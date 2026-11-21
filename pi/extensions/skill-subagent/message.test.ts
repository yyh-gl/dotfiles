import { describe, expect, test } from "bun:test";
import { extractAssistantText } from "./message.ts";

describe("extractAssistantText", () => {
	test("contentがtext要素1件のみならそのテキストを返す", () => {
		expect(extractAssistantText({ role: "assistant", content: [{ type: "text", text: "こんにちは" }] })).toBe(
			"こんにちは",
		);
	});
});
