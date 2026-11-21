export interface QuestionOptionInput {
	label: string;
	description?: string;
}

export interface QuestionInput {
	question: string;
	header: string;
	options: QuestionOptionInput[];
	multiSelect?: boolean;
}

export interface AnsweredQuestion {
	question: string;
	header: string;
	selectedLabels: string[];
	customText?: string;
	answer: string;
}

export interface QuestionsResult {
	cancelled: boolean;
	answers: AnsweredQuestion[];
}

export function buildAnswer(
	question: Pick<QuestionInput, "question" | "header">,
	selectedOptions: QuestionOptionInput[],
	customText: string | undefined,
): AnsweredQuestion {
	const selectedLabels = selectedOptions.map((o) => o.label);
	const parts = [...selectedLabels];
	if (customText) parts.push(customText);
	return {
		question: question.question,
		header: question.header,
		selectedLabels,
		customText,
		answer: parts.join(", "),
	};
}
