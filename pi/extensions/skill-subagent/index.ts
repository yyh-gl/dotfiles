import { readFileSync } from "node:fs";
import { dirname } from "node:path";
import type { ExtensionAPI, InputEventResult } from "@earendil-works/pi-coding-agent";
import { parseFrontmatter } from "@earendil-works/pi-coding-agent";
import { findSkillCommand } from "./commands.ts";
import { shouldIgnoreInputEvent } from "./input-event.ts";
import { hasSubagentDirective, isValidThinkingLevel, resolveThinkingLevel, splitModelReference } from "./model.ts";
import { parseSkillInvocation } from "./parse.ts";
import { buildSubagentPrompt } from "./prompt.ts";
import { runSkillSubagent } from "./process.ts";

export default function skillSubagent(pi: ExtensionAPI) {
	pi.on("input", async (event, ctx): Promise<InputEventResult> => {
		if (shouldIgnoreInputEvent(event.source)) return { action: "continue" };

		const invocation = parseSkillInvocation(event.text);
		if (!invocation) return { action: "continue" };

		const command = findSkillCommand(pi.getCommands(), invocation.skillName);
		if (!command) return { action: "continue" };

		const fileContent = readFileSync(command.sourceInfo.path, "utf-8");
		const { frontmatter, body } = parseFrontmatter<Record<string, unknown>>(fileContent);
		if (!hasSubagentDirective(frontmatter)) return { action: "continue" };

		let model = ctx.model;
		if (frontmatter.model != null) {
			const reference = splitModelReference(frontmatter.model);
			const resolved = reference ? ctx.modelRegistry.find(reference.provider, reference.modelId) : undefined;
			if (!resolved || !ctx.modelRegistry.hasConfiguredAuth(resolved)) {
				ctx.ui.notify(
					`スキル"${invocation.skillName}"のmodel指定(${String(frontmatter.model)})を解決できなかったため、通常の呼び出しにフォールバックします。`,
					"warning",
				);
				return { action: "continue" };
			}
			model = resolved;
		}

		const fallbackThinkingLevel = ctx.thinkingLevel ?? pi.getThinkingLevel();
		if (frontmatter.effort != null && !isValidThinkingLevel(frontmatter.effort)) {
			ctx.ui.notify(
				`スキル"${invocation.skillName}"のeffort指定(${String(frontmatter.effort)})が無効なため、現在のthinking levelにフォールバックします。`,
				"warning",
			);
		}
		const thinkingLevel = resolveThinkingLevel(frontmatter.effort, fallbackThinkingLevel);

		const baseDir = dirname(command.sourceInfo.path);
		const prompt = buildSubagentPrompt({ baseDir, body, args: invocation.args });

		await runSkillSubagent(ctx, { model, thinkingLevel, prompt });
		return { action: "handled" };
	});
}
