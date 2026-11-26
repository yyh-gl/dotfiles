import { describe, expect, test } from "bun:test";
import { extractAssistantText } from "./message.ts";

describe("extractAssistantText", () => {
	test("contentがtext要素1件のみならそのテキストを返す", () => {
		expect(extractAssistantText({ role: "assistant", content: [{ type: "text", text: "こんにちは" }] })).toBe(
			"こんにちは",
		);
	});

	test("thinking→text→toolCallの順で混在していてもtext要素のみ抜き出す", () => {
		expect(
			extractAssistantText({
				role: "assistant",
				content: [
					{ type: "thinking", text: "考え中" },
					{ type: "text", text: "回答です" },
					{ type: "toolCall" },
				],
			}),
		).toBe("回答です");
	});

	test("contentが空配列なら空文字列を返す", () => {
		expect(extractAssistantText({ role: "assistant", content: [] })).toBe("");
	});

	test("roleがassistant以外なら空文字列を返す", () => {
		expect(extractAssistantText({ role: "toolResult", content: [{ type: "text", text: "無視される" }] })).toBe("");
	});

	test("text要素が複数ある場合は区切りなしで連結する", () => {
		expect(
			extractAssistantText({
				role: "assistant",
				content: [
					{ type: "text", text: "こん" },
					{ type: "text", text: "にちは" },
				],
			}),
		).toBe("こんにちは");
	});
});
