import type { QuestionOptionInput } from "./questions.ts";

export const OTHER_LABEL = "その他（自由入力）";

export type SelectChoice = { kind: "option"; option: QuestionOptionInput } | { kind: "other" };

export interface SelectChoices {
	optionStrings: string[];
	lookup: Map<string, SelectChoice>;
}

function formatOption(option: QuestionOptionInput): string {
	return option.description ? `${option.label} — ${option.description}` : option.label;
}

export function buildSelectChoices(options: QuestionOptionInput[]): SelectChoices {
	const lookup = new Map<string, SelectChoice>();
	const optionStrings = options.map((option) => {
		const display = formatOption(option);
		lookup.set(display, { kind: "option", option });
		return display;
	});
	optionStrings.push(OTHER_LABEL);
	lookup.set(OTHER_LABEL, { kind: "other" });
	return { optionStrings, lookup };
}
