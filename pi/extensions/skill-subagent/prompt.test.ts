import { describe, expect, test } from "bun:test";
import { buildSubagentPrompt } from "./prompt.ts";

describe("buildSubagentPrompt", () => {
	test("argsがあれば末尾に追加する", () => {
		expect(buildSubagentPrompt({ baseDir: "/base", body: "body text", args: "args text" })).toBe(
			"References are relative to /base.\n\nbody text\n\nargs text",
		);
	});
});
