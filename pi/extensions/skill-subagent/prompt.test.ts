import { describe, expect, test } from "bun:test";
import { buildSubagentPrompt } from "./prompt.ts";

describe("buildSubagentPrompt", () => {
	test("argsがあれば末尾に追加する", () => {
		expect(buildSubagentPrompt({ baseDir: "/base", body: "body text", args: "args text" })).toBe(
			"References are relative to /base.\n\nbody text\n\nargs text",
		);
	});

	test("argsが空文字なら末尾に余分な改行を付けない", () => {
		expect(buildSubagentPrompt({ baseDir: "/base", body: "body text", args: "" })).toBe(
			"References are relative to /base.\n\nbody text",
		);
	});

	test("bodyの前後の空白・改行はtrimしてから埋め込む", () => {
		expect(buildSubagentPrompt({ baseDir: "/base", body: "\n  body text  \n", args: "" })).toBe(
			"References are relative to /base.\n\nbody text",
		);
	});

	test("bodyが空文字の場合もそのまま埋め込まれる", () => {
		expect(buildSubagentPrompt({ baseDir: "/base", body: "", args: "" })).toBe("References are relative to /base.\n\n");
	});

	test("baseDirに日本語・スペースを含むパスがそのまま埋め込まれる", () => {
		expect(buildSubagentPrompt({ baseDir: "/base ディレクトリ", body: "body", args: "" })).toBe(
			"References are relative to /base ディレクトリ.\n\nbody",
		);
	});
});
