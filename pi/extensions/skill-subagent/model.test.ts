import { describe, expect, test } from "bun:test";
import { hasSubagentDirective, isValidThinkingLevel, resolveThinkingLevel, splitModelReference } from "./model.ts";

describe("splitModelReference", () => {
	test("provider/model-id形式を最初の/で分割する", () => {
		expect(splitModelReference("anthropic/claude-opus-4-5")).toEqual({
			provider: "anthropic",
			modelId: "claude-opus-4-5",
		});
	});

	test("modelId自体に/を含む場合は最初の/だけで区切る", () => {
		expect(splitModelReference("openrouter/anthropic/claude-3-opus")).toEqual({
			provider: "openrouter",
			modelId: "anthropic/claude-3-opus",
		});
	});

	test("/を含まない文字列はundefinedになる", () => {
		expect(splitModelReference("opus")).toBeUndefined();
	});

	test.each([[123], [null], [undefined], [true], [[]], [{}]])("非文字列(%p)はundefinedになる", (value) => {
		expect(splitModelReference(value)).toBeUndefined();
	});

	test("空文字列はundefinedになる", () => {
		expect(splitModelReference("")).toBeUndefined();
	});

	test("先頭が/の場合はundefinedになる", () => {
		expect(splitModelReference("/claude-opus")).toBeUndefined();
	});

	test("末尾が/の場合はundefinedになる", () => {
		expect(splitModelReference("anthropic/")).toBeUndefined();
	});
});

describe("isValidThinkingLevel", () => {
	test.each(["off", "minimal", "low", "medium", "high", "xhigh", "max"])("%sは妥当な値である", (level) => {
		expect(isValidThinkingLevel(level)).toBe(true);
	});

	test.each(["XHIGH", "Off", "ultra", ""])("大文字小文字違いや未知の文字列(%p)は妥当ではない", (level) => {
		expect(isValidThinkingLevel(level)).toBe(false);
	});

	test.each([[true], [false], [123], [null], [undefined], [[]]])("非文字列(%p)は妥当ではない", (value) => {
		expect(isValidThinkingLevel(value)).toBe(false);
	});
});

describe("resolveThinkingLevel", () => {
	test("valueが有効な7値のいずれかならそのまま返す", () => {
		expect(resolveThinkingLevel("xhigh", "off")).toBe("xhigh");
	});

	test("valueが無効な値ならfallbackを返す", () => {
		expect(resolveThinkingLevel("ultra", "medium")).toBe("medium");
	});

	test("valueがundefinedならfallbackを返す", () => {
		expect(resolveThinkingLevel(undefined, "medium")).toBe("medium");
	});
});

describe("hasSubagentDirective", () => {
	test("modelもeffortも無ければfalse", () => {
		expect(hasSubagentDirective({})).toBe(false);
	});
});
