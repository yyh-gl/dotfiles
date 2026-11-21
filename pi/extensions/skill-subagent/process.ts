import { spawn } from "node:child_process";
import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { Model } from "@earendil-works/pi-ai";
import { Key, matchesKey } from "@earendil-works/pi-tui";
import { feedNdjsonChunk, parseNdjsonLine } from "./ndjson.ts";
import { extractAssistantText } from "./message.ts";
import type { ThinkingLevelValue } from "./model.ts";
import { buildCtxUiCall, buildUiResponse } from "./ui-request.ts";

export interface RunSkillSubagentOptions {
	model: Model<any> | undefined;
	thinkingLevel: ThinkingLevelValue;
	prompt: string;
}

const KILL_GRACE_PERIOD_MS = 5000;
const PROMPT_COMMAND_ID = "skill-subagent-prompt";

function buildSpawnArgs(options: RunSkillSubagentOptions): string[] {
	const args = ["--mode", "rpc", "--no-session", "--thinking", options.thinkingLevel];
	if (options.model) {
		args.push("--provider", options.model.provider, "--model", options.model.id);
	}
	return args;
}

export async function runSkillSubagent(ctx: ExtensionContext, options: RunSkillSubagentOptions): Promise<void> {
	const child = spawn("pi", buildSpawnArgs(options), { cwd: ctx.cwd, stdio: ["pipe", "pipe", "pipe"] });

	await new Promise<void>((resolve) => {
		let settled = false;
		let pending = "";
		let unsubscribeTerminalInput: (() => void) | undefined;

		function finish() {
			if (settled) return;
			settled = true;
			unsubscribeTerminalInput?.();
			resolve();
		}

		function send(obj: unknown) {
			child.stdin.write(`${JSON.stringify(obj)}\n`);
		}

		async function handleLine(line: string) {
			const message = parseNdjsonLine(line);
			if (!message || typeof message !== "object") return;
			const event = message as { type?: string; id?: string; message?: unknown };

			if (event.type === "response" && event.id === PROMPT_COMMAND_ID) {
				const response = message as { success: boolean; error?: string };
				if (!response.success) {
					ctx.ui.notify(`サブエージェントの起動に失敗しました: ${response.error}`, "error");
					child.kill("SIGTERM");
				}
				return;
			}

			if (event.type === "extension_ui_request") {
				const request = message as Parameters<typeof buildCtxUiCall>[0];
				const call = buildCtxUiCall(request);
				let result: string | boolean | undefined;
				switch (call.method) {
					case "select":
						result = await ctx.ui.select(...call.args);
						break;
					case "confirm":
						result = await ctx.ui.confirm(...call.args);
						break;
					case "input":
						result = await ctx.ui.input(...call.args);
						break;
					case "editor":
						result = await ctx.ui.editor(...call.args);
						break;
					case "none":
						return;
				}
				send(buildUiResponse(request.id, result));
				return;
			}

			if (event.type === "message_end") {
				const text = extractAssistantText(event.message as Parameters<typeof extractAssistantText>[0]);
				if (text) ctx.ui.notify(text, "info");
				return;
			}

			if (event.type === "agent_settled") {
				child.stdin.end();
				finish();
			}
		}

		child.stdout.on("data", (chunk: Buffer) => {
			const { lines, pending: nextPending } = feedNdjsonChunk(pending, chunk.toString("utf-8"));
			pending = nextPending;
			for (const line of lines) void handleLine(line);
		});

		child.on("error", (error) => {
			ctx.ui.notify(`サブエージェントの起動に失敗しました: ${error.message}`, "error");
			finish();
		});

		child.on("exit", finish);

		unsubscribeTerminalInput = ctx.ui.onTerminalInput((data) => {
			if (!matchesKey(data, Key.escape)) return undefined;
			child.kill("SIGTERM");
			setTimeout(() => {
				if (child.exitCode === null && child.signalCode === null) child.kill("SIGKILL");
			}, KILL_GRACE_PERIOD_MS);
			return { consume: true };
		});

		send({ type: "prompt", id: PROMPT_COMMAND_ID, message: options.prompt });
	});
}
