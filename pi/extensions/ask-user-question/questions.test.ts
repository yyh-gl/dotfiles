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

	test("multiSelectで複数選んだ場合、selectedLabelsは元の選択肢の順序で並び、answerは', 'で連結したもの", () => {
		const question = { question: "好きな色は?", header: "色" };
		expect(buildAnswer(question, [{ label: "赤" }, { label: "青" }], undefined)).toEqual({
			question: "好きな色は?",
			header: "色",
			selectedLabels: ["赤", "青"],
			customText: undefined,
			answer: "赤, 青",
		});
	});

	test("customText(自由入力)がある場合、selectedLabelsの末尾にcustomTextを追加した文字列がanswerになる", () => {
		const question = { question: "好きな色は?", header: "色" };
		expect(buildAnswer(question, [{ label: "赤" }], "紫っぽい赤")).toEqual({
			question: "好きな色は?",
			header: "色",
			selectedLabels: ["赤"],
			customText: "紫っぽい赤",
			answer: "赤, 紫っぽい赤",
		});
	});

	test("multiSelectで選択肢を何も選ばずcustomTextだけの場合、answerはcustomTextのみ", () => {
		const question = { question: "好きな色は?", header: "色" };
		expect(buildAnswer(question, [], "緑")).toEqual({
			question: "好きな色は?",
			header: "色",
			selectedLabels: [],
			customText: "緑",
			answer: "緑",
		});
	});
});
