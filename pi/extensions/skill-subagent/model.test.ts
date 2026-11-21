import { describe, expect, test } from "bun:test";
import { splitModelReference } from "./model.ts";

describe("splitModelReference", () => {
	test("provider/model-id形式を最初の/で分割する", () => {
		expect(splitModelReference("anthropic/claude-opus-4-5")).toEqual({
			provider: "anthropic",
			modelId: "claude-opus-4-5",
		});
	});
});
