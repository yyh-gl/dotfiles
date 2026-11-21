import { describe, expect, test } from "bun:test";
import { runQuestionsUIRpc } from "./questions-rpc.ts";
import type { QuestionInput } from "./questions.ts";

function fakeUi(script: { select?: (string | undefined)[]; confirm?: boolean[]; input?: (string | undefined)[] }) {
	const select = [...(script.select ?? [])];
	const confirm = [...(script.confirm ?? [])];
	const input = [...(script.input ?? [])];
	return {
		select: async () => select.shift(),
		confirm: async () => confirm.shift() ?? false,
		input: async () => input.shift(),
	};
}

describe("runQuestionsUIRpc", () => {
	test("単一選択の問いでselectで選んだ選択肢がそのままanswerになる", async () => {
		const questions: QuestionInput[] = [
			{ question: "好きな色は?", header: "色", options: [{ label: "赤" }, { label: "青" }] },
		];
		const ui = fakeUi({ select: ["赤"] });

		const result = await runQuestionsUIRpc(ui, questions);

		expect(result).toEqual({
			cancelled: false,
			answers: [{ question: "好きな色は?", header: "色", selectedLabels: ["赤"], customText: undefined, answer: "赤" }],
		});
	});
});
