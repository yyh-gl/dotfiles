import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import type { QuestionsResult } from "./questions.ts";
import { runQuestionsUI } from "./ui.ts";

const OptionSchema = Type.Object({
	label: Type.String({ description: "Display label for the option. Put the recommended option first and append (Recommended) to its label." }),
	description: Type.Optional(Type.String({ description: "Optional one-line description shown below the label." })),
});

const QuestionSchema = Type.Object({
	question: Type.String({ description: "The full question text to show the user." }),
	header: Type.String({ maxLength: 12, description: "Short tab label for this question (max 12 characters)." }),
	options: Type.Array(OptionSchema, {
		minItems: 2,
		maxItems: 4,
		description: "2 to 4 options. Do not add a free-text 'other' option; it is added automatically.",
	}),
	multiSelect: Type.Optional(Type.Boolean({ description: "Allow selecting multiple options. Defaults to false." })),
});

const AskUserQuestionParams = Type.Object({
	questions: Type.Array(QuestionSchema, { minItems: 1, maxItems: 4, description: "1 to 4 questions to ask the user." }),
});

export default function askUserQuestion(pi: ExtensionAPI) {
	pi.registerTool({
		name: "ask_user_question",
		label: "Ask User Question",
		description:
			"Ask the user one to four multiple-choice questions and wait for their answers. Use when you need the user to clarify requirements, make a decision, or choose between options. Each question shows 2-4 options plus an automatic free-text 'other' option; put the recommended option first and mark it with (Recommended) in its label.",
		parameters: AskUserQuestionParams,
		executionMode: "sequential",

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			if (ctx.mode !== "tui") {
				return {
					content: [
						{
							type: "text",
							text: "Error: ask_user_question's UI is not available in this mode. Ask the user the same questions as plain text, one at a time, instead.",
						},
					],
					details: undefined,
					isError: true,
				};
			}

			const seenQuestions = new Set<string>();
			for (const q of params.questions) {
				if (seenQuestions.has(q.question)) {
					throw new Error(`Duplicate question text: "${q.question}"`);
				}
				seenQuestions.add(q.question);

				const seenLabels = new Set<string>();
				for (const opt of q.options) {
					if (seenLabels.has(opt.label)) {
						throw new Error(`Duplicate option label "${opt.label}" in question "${q.question}"`);
					}
					seenLabels.add(opt.label);
				}
			}

			const result = await runQuestionsUI(ctx, params.questions);

			if (result.cancelled) {
				return {
					content: [{ type: "text", text: "User declined to answer the questions." }],
					details: result,
				};
			}

			const parts = result.answers.map((a) => `"${a.question}"="${a.answer}"`);
			return {
				content: [
					{
						type: "text",
						text: `User has answered your questions: ${parts.join(", ")}. You can now continue with the user's answers in mind.`,
					},
				],
				details: result,
			};
		},

		renderCall(args, theme) {
			const qs = (args as { questions?: { header?: string }[] }).questions ?? [];
			const headers = qs.map((q) => q.header).filter((h): h is string => !!h).join(", ");
			let text = theme.fg("toolTitle", theme.bold("ask_user_question "));
			text += theme.fg("muted", `${qs.length} question${qs.length !== 1 ? "s" : ""}`);
			if (headers) text += theme.fg("dim", ` (${headers})`);
			return new Text(text, 0, 0);
		},

		renderResult(result, _options, theme) {
			const details = result.details as QuestionsResult | undefined;
			if (!details) {
				const text = result.content[0];
				return new Text(text?.type === "text" ? text.text : "", 0, 0);
			}
			if (details.cancelled) {
				return new Text(theme.fg("warning", "キャンセル"), 0, 0);
			}
			const lines = details.answers.map(
				(a) => `${theme.fg("success", "✓ ")}${theme.fg("accent", a.header)}: ${a.answer}`,
			);
			return new Text(lines.join("\n"), 0, 0);
		},
	});
}
