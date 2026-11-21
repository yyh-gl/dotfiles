import { describe, expect, test } from "bun:test";
import { runQuestionsUIRpc } from "./questions-rpc.ts";
import type { RpcQuestionsUi } from "./questions-rpc.ts";
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

	test("単一選択で「その他」を選ぶとinputの自由入力がcustomTextになる", async () => {
		const questions: QuestionInput[] = [{ question: "好きな色は?", header: "色", options: [{ label: "赤" }, { label: "青" }] }];
		const ui = fakeUi({ select: ["その他（自由入力）"], input: ["紫"] });

		const result = await runQuestionsUIRpc(ui, questions);

		expect(result).toEqual({
			cancelled: false,
			answers: [{ question: "好きな色は?", header: "色", selectedLabels: [], customText: "紫", answer: "紫" }],
		});
	});

	test("単一選択でselectがキャンセル(undefined)された場合はcancelled:trueになる", async () => {
		const questions: QuestionInput[] = [{ question: "好きな色は?", header: "色", options: [{ label: "赤" }, { label: "青" }] }];
		const ui = fakeUi({ select: [undefined] });

		const result = await runQuestionsUIRpc(ui, questions);

		expect(result).toEqual({ cancelled: true, answers: [] });
	});

	test("単一選択で「その他」選択後にinputがキャンセル(undefined)された場合はcancelled:trueになる", async () => {
		const questions: QuestionInput[] = [{ question: "好きな色は?", header: "色", options: [{ label: "赤" }, { label: "青" }] }];
		const ui = fakeUi({ select: ["その他（自由入力）"], input: [undefined] });

		const result = await runQuestionsUIRpc(ui, questions);

		expect(result).toEqual({ cancelled: true, answers: [] });
	});

	test("multiSelectで複数confirmして選んだ選択肢がselectedLabelsになる", async () => {
		const questions: QuestionInput[] = [
			{ question: "好きな色は?", header: "色", multiSelect: true, options: [{ label: "赤" }, { label: "青" }] },
		];
		const ui = fakeUi({ confirm: [true, true, false] });

		const result = await runQuestionsUIRpc(ui, questions);

		expect(result).toEqual({
			cancelled: false,
			answers: [
				{ question: "好きな色は?", header: "色", selectedLabels: ["赤", "青"], customText: undefined, answer: "赤, 青" },
			],
		});
	});

	test("multiSelectで全てのconfirmがfalseかつ「その他を追加しますか」もfalseの場合は空回答で次へ進む", async () => {
		const questions: QuestionInput[] = [
			{ question: "好きな色は?", header: "色", multiSelect: true, options: [{ label: "赤" }, { label: "青" }] },
		];
		const ui = fakeUi({ confirm: [false, false, false] });

		const result = await runQuestionsUIRpc(ui, questions);

		expect(result).toEqual({
			cancelled: false,
			answers: [{ question: "好きな色は?", header: "色", selectedLabels: [], customText: undefined, answer: "" }],
		});
	});

	test("multiSelectで「その他を追加しますか」にtrueで答えるとinputの値がcustomTextに追加される", async () => {
		const questions: QuestionInput[] = [
			{ question: "好きな色は?", header: "色", multiSelect: true, options: [{ label: "赤" }, { label: "青" }] },
		];
		const ui = fakeUi({ confirm: [true, false, true], input: ["緑"] });

		const result = await runQuestionsUIRpc(ui, questions);

		expect(result).toEqual({
			cancelled: false,
			answers: [
				{ question: "好きな色は?", header: "色", selectedLabels: ["赤"], customText: "緑", answer: "赤, 緑" },
			],
		});
	});

	test("複数の問いは順番に処理され、途中でキャンセルされると残りの問いは聞かれない", async () => {
		const questions: QuestionInput[] = [
			{ question: "Q1", header: "h1", options: [{ label: "a" }, { label: "b" }] },
			{ question: "Q2", header: "h2", options: [{ label: "c" }, { label: "d" }] },
		];
		let selectCallCount = 0;
		const ui: RpcQuestionsUi = {
			select: async () => {
				selectCallCount += 1;
				return undefined;
			},
			confirm: async () => false,
			input: async () => undefined,
		};

		const result = await runQuestionsUIRpc(ui, questions);

		expect(result).toEqual({ cancelled: true, answers: [] });
		expect(selectCallCount).toBe(1);
	});
});
