import { buildMultiSelectConfirmMessage, buildSelectChoices } from "./choices.ts";
import { buildAnswer } from "./questions.ts";
import type { AnsweredQuestion, QuestionInput, QuestionOptionInput, QuestionsResult } from "./questions.ts";

export interface RpcQuestionsUi {
	select(title: string, options: string[]): Promise<string | undefined>;
	confirm(title: string, message: string): Promise<boolean>;
	input(title: string, placeholder?: string): Promise<string | undefined>;
}

const OTHER_PLACEHOLDER = "自由入力";
const ADD_OTHER_PROMPT = "その他を追加しますか？";

type AnswerOutcome = { cancelled: true } | { cancelled: false; answer: AnsweredQuestion };

async function askSingleSelect(ui: RpcQuestionsUi, question: QuestionInput): Promise<AnswerOutcome> {
	const { optionStrings, lookup } = buildSelectChoices(question.options);
	const chosen = await ui.select(question.question, optionStrings);
	if (chosen === undefined) return { cancelled: true };

	const choice = lookup.get(chosen);
	if (choice?.kind === "option") {
		return { cancelled: false, answer: buildAnswer(question, [choice.option], undefined) };
	}

	const customText = await ui.input(question.question, OTHER_PLACEHOLDER);
	if (customText === undefined) return { cancelled: true };
	return { cancelled: false, answer: buildAnswer(question, [], customText) };
}

async function askMultiSelect(ui: RpcQuestionsUi, question: QuestionInput): Promise<AnswerOutcome> {
	const selectedOptions: QuestionOptionInput[] = [];
	for (const option of question.options) {
		const selected = await ui.confirm(question.question, buildMultiSelectConfirmMessage(option.label));
		if (selected) selectedOptions.push(option);
	}

	const addOther = await ui.confirm(question.question, ADD_OTHER_PROMPT);
	if (!addOther) return { cancelled: false, answer: buildAnswer(question, selectedOptions, undefined) };

	const customText = await ui.input(question.question, OTHER_PLACEHOLDER);
	if (customText === undefined) return { cancelled: true };
	return { cancelled: false, answer: buildAnswer(question, selectedOptions, customText) };
}

export async function runQuestionsUIRpc(ui: RpcQuestionsUi, questions: QuestionInput[]): Promise<QuestionsResult> {
	const answers: AnsweredQuestion[] = [];
	for (const question of questions) {
		const outcome = question.multiSelect ? await askMultiSelect(ui, question) : await askSingleSelect(ui, question);
		if (outcome.cancelled) return { cancelled: true, answers: [] };
		answers.push(outcome.answer);
	}
	return { cancelled: false, answers };
}
