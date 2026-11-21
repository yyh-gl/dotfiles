import { describe, expect, test } from "bun:test";
import { parseSkillInvocation } from "./parse.ts";

describe("parseSkillInvocation", () => {
	test("skill名とargsを空白区切りで分解する", () => {
		expect(parseSkillInvocation("/skill:ponder 計画のテキスト")).toEqual({
			skillName: "ponder",
			args: "計画のテキスト",
		});
	});
});
