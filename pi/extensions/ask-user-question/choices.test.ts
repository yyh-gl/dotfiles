import { describe, expect, test } from "bun:test";
import { buildMultiSelectConfirmMessage, buildSelectChoices, OTHER_LABEL } from "./choices.ts";

describe("buildSelectChoices", () => {
	test("description有りの選択肢はoptionStringsで'label — description'になる", () => {
		const { optionStrings } = buildSelectChoices([{ label: "赤", description: "暖色" }, { label: "青" }]);
		expect(optionStrings[0]).toBe("赤 — 暖色");
	});

	test("description無しの選択肢はoptionStringsでlabelのみになる", () => {
		const { optionStrings } = buildSelectChoices([{ label: "赤", description: "暖色" }, { label: "青" }]);
		expect(optionStrings[1]).toBe("青");
	});

	test("選択肢が最小2件ならoptionStringsは3件(選択肢2+その他1)、lookupのサイズも3", () => {
		const { optionStrings, lookup } = buildSelectChoices([{ label: "赤" }, { label: "青" }]);
		expect(optionStrings).toHaveLength(3);
		expect(lookup.size).toBe(3);
	});

	test("選択肢が最大4件ならoptionStringsは5件", () => {
		const { optionStrings } = buildSelectChoices([
			{ label: "赤" },
			{ label: "青" },
			{ label: "緑" },
			{ label: "黄" },
		]);
		expect(optionStrings).toHaveLength(5);
	});

	test("「その他（自由入力）」が常に配列の末尾に来る", () => {
		const { optionStrings } = buildSelectChoices([{ label: "赤" }, { label: "青" }]);
		expect(optionStrings.at(-1)).toBe(OTHER_LABEL);
	});

	test("optionStringsの各要素をlookupで検索すると対応する元の選択肢を完全一致で取得できる", () => {
		const options = [{ label: "赤", description: "暖色" }, { label: "青" }];
		const { optionStrings, lookup } = buildSelectChoices(options);
		expect(lookup.get(optionStrings[0])).toEqual({ kind: "option", option: options[0] });
		expect(lookup.get(optionStrings[1])).toEqual({ kind: "option", option: options[1] });
		expect(lookup.get(optionStrings[2])).toEqual({ kind: "other" });
	});

	test("同じlabelでdescriptionだけ異なる2つの選択肢は別々のキーとしてそれぞれ正しく指す", () => {
		const optionA = { label: "赤", description: "descA" };
		const optionB = { label: "赤", description: "descB" };
		const { optionStrings, lookup } = buildSelectChoices([optionA, optionB]);
		expect(optionStrings[0]).toBe("赤 — descA");
		expect(optionStrings[1]).toBe("赤 — descB");
		expect(lookup.get("赤 — descA")).toEqual({ kind: "option", option: optionA });
		expect(lookup.get("赤 — descB")).toEqual({ kind: "option", option: optionB });
	});
});

describe("buildMultiSelectConfirmMessage", () => {
	test("通常のlabelがそのまま埋め込まれる", () => {
		expect(buildMultiSelectConfirmMessage("赤")).toBe("赤を選びますか？");
	});

	test("labelに\"や改行を含む場合でもエスケープせずそのまま埋め込まれる", () => {
		expect(buildMultiSelectConfirmMessage('赤"青\n緑')).toBe('赤"青\n緑を選びますか？');
	});
});
