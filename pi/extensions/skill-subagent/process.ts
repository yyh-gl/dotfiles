import { spawn } from "node:child_process";
import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { Model } from "@earendil-works/pi-ai";
import { Key, matchesKey } from "@earendil-works/pi-tui";
import { createBufferDecoder, feedNdjsonChunk, parseNdjsonLine } from "./ndjson.ts";
import { extractAssistantText } from "./message.ts";
import type { ThinkingLevelValue } from "./model.ts";
import { buildCtxUiCall, buildUiResponse } from "./ui-request.ts";

export interface RunSkillSubagentOptions {
	model: Model<any> | undefined;
	thinkingLevel: ThinkingLevelValue;
	prompt: string;
}

const KILL_GRACE_PERIOD_MS = 5000;
const STDERR_TAIL_LIMIT = 4000;
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
		let agentSettled = false;
		let terminationRequested = false;
		let pending = "";
		let stderrTail = "";
		let currentDialogAbort: AbortController | undefined;
		let unsubscribeTerminalInput: (() => void) | undefined;
		const decodeStdoutChunk = createBufferDecoder();
		const decodeStderrChunk = createBufferDecoder();

		function finish() {
			if (settled) return;
			settled = true;
			currentDialogAbort?.abort();
			unsubscribeTerminalInput?.();
			resolve();
		}

		function terminateChild() {
			terminationRequested = true;
			child.kill("SIGTERM");
			setTimeout(() => {
				if (child.exitCode === null && child.signalCode === null) child.kill("SIGKILL");
			}, KILL_GRACE_PERIOD_MS);
		}

		function send(obj: unknown) {
			if (settled || !child.stdin.writable) return;
			child.stdin.write(`${JSON.stringify(obj)}\n`);
		}

		async function withDialogAbort<T>(run: (signal: AbortSignal) => Promise<T>): Promise<T> {
			const controller = new AbortController();
			currentDialogAbort = controller;
			try {
				return await run(controller.signal);
			} finally {
				if (currentDialogAbort === controller) currentDialogAbort = undefined;
			}
		}

		async function handleLine(line: string) {
			const message = parseNdjsonLine(line);
			if (!message || typeof message !== "object") return;
			const event = message as { type?: string; id?: string; message?: unknown };

			if (event.type === "response" && event.id === PROMPT_COMMAND_ID) {
				const response = message as { success: boolean; error?: string };
				if (!response.success) {
					ctx.ui.notify(`サブエージェントの起動に失敗しました: ${response.error}`, "error");
					terminateChild();
				}
				return;
			}

			if (event.type === "extension_ui_request") {
				const request = message as Parameters<typeof buildCtxUiCall>[0];
				const call = buildCtxUiCall(request);
				let result: string | boolean | undefined;
				switch (call.method) {
					case "select":
						result = await withDialogAbort((signal) => ctx.ui.select(...call.args, { signal }));
						break;
					case "confirm":
						result = await withDialogAbort((signal) => ctx.ui.confirm(...call.args, { signal }));
						break;
					case "input":
						result = await withDialogAbort((signal) => ctx.ui.input(...call.args, { signal }));
						break;
					case "editor":
						// ExtensionUIContext.editor() takes no AbortSignal, so an Escape while it is open
						// cannot cancel just this dialog; it falls through to the no-dialog-in-flight path
						// and terminates the whole subagent instead. ask-user-question's RPC UI never emits
						// an editor request (decision 8), so this is a dormant branch for other callers.
						result = await ctx.ui.editor(...call.args);
						break;
					case "notify":
						ctx.ui.notify(...call.args);
						return;
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
				agentSettled = true;
				child.stdin.end();
				finish();
			}
		}

		child.stdout.on("data", (chunk: Buffer) => {
			const { lines, pending: nextPending } = feedNdjsonChunk(pending, decodeStdoutChunk(chunk));
			pending = nextPending;
			for (const line of lines) {
				handleLine(line).catch((error) => ctx.ui.notify(String(error), "error"));
			}
		});

		child.stderr.on("data", (chunk: Buffer) => {
			stderrTail = (stderrTail + decodeStderrChunk(chunk)).slice(-STDERR_TAIL_LIMIT);
		});

		child.stdin.on("error", () => {
			// Writing after the child has exited or been killed raises EPIPE; terminateChild()/finish()
			// already handle the lifecycle, so there is nothing more to do here than avoid crashing on it.
		});

		child.on("error", (error) => {
			ctx.ui.notify(`サブエージェントの起動に失敗しました: ${error.message}`, "error");
			finish();
		});

		child.on("close", (code) => {
			if (!agentSettled && !terminationRequested && code !== 0) {
				ctx.ui.notify(`サブエージェントが異常終了しました(code=${code}): ${stderrTail.trim()}`, "error");
			}
			finish();
		});

		unsubscribeTerminalInput = ctx.ui.onTerminalInput((data) => {
			if (!matchesKey(data, Key.escape)) return undefined;
			if (currentDialogAbort) {
				currentDialogAbort.abort();
			} else {
				terminateChild();
			}
			return { consume: true };
		});

		send({ type: "prompt", id: PROMPT_COMMAND_ID, message: options.prompt });
	});
}
