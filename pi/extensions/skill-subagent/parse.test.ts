import { describe, expect, test } from "bun:test";
import { parseSkillInvocation } from "./parse.ts";

describe("parseSkillInvocation", () => {
	test("skill名とargsを空白区切りで分解する", () => {
		expect(parseSkillInvocation("/skill:ponder 計画のテキスト")).toEqual({
			skillName: "ponder",
			args: "計画のテキスト",
		});
	});

	test("スペースを含まない場合、argsは空文字になる", () => {
		expect(parseSkillInvocation("/skill:ponder")).toEqual({ skillName: "ponder", args: "" });
	});

	test.each(["ponder", "skill:ponder", "/ponder"])("'/skill:'で始まらないテキスト(%s)はundefinedになる", (text) => {
		expect(parseSkillInvocation(text)).toBeUndefined();
	});

	test("2個目以降のスペースを含めて全体がargsになる", () => {
		expect(parseSkillInvocation("/skill:ponder a b c")).toEqual({ skillName: "ponder", args: "a b c" });
	});

	test("末尾がスペースのみの場合、argsは空文字になる", () => {
		expect(parseSkillInvocation("/skill:ponder ")).toEqual({ skillName: "ponder", args: "" });
	});

	test("argsの前後の余分な空白は落ちるが中間の空白は保持される", () => {
		expect(parseSkillInvocation("/skill:ponder   plan with spaces  ")).toEqual({
			skillName: "ponder",
			args: "plan with spaces",
		});
	});

	test("スキル名直後がタブ・改行の場合、区切りとして扱われず全体がskillNameに取り込まれる", () => {
		expect(parseSkillInvocation("/skill:ponder\nargs")).toEqual({ skillName: "ponder\nargs", args: "" });
	});

	test("'/skill:'のみの場合、skillNameは空文字になる", () => {
		expect(parseSkillInvocation("/skill:")).toEqual({ skillName: "", args: "" });
	});

	test("スキル名にコロンを含む場合もそのままskillNameに取り込まれる", () => {
		expect(parseSkillInvocation("/skill:foo:bar args")).toEqual({ skillName: "foo:bar", args: "args" });
	});
});
