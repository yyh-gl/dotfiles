import { describe, expect, test } from "bun:test";
import { buildAnswer } from "./questions.ts";

describe("buildAnswer", () => {
	test("単一選択で1つ選んだ場合、answerはそのlabelのみ・selectedLabelsは1件", () => {
		const question = { question: "好きな色は?", header: "色" };
		expect(buildAnswer(question, [{ label: "赤" }], undefined)).toEqual({
			question: "好きな色は?",
			header: "色",
			selectedLabels: ["赤"],
			customText: undefined,
			answer: "赤",
		});
	});
});
