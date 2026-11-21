import { describe, expect, test } from "bun:test";
import { buildSelectChoices } from "./choices.ts";

describe("buildSelectChoices", () => {
	test("description有りの選択肢はoptionStringsで'label — description'になる", () => {
		const { optionStrings } = buildSelectChoices([{ label: "赤", description: "暖色" }, { label: "青" }]);
		expect(optionStrings[0]).toBe("赤 — 暖色");
	});
});
