import { describe, expect, test } from "bun:test";
import { findSkillCommand } from "./commands.ts";

function command(name: string, source: "skill" | "extension" | "prompt", path: string) {
	return { name, source, sourceInfo: { path, source, scope: "project" as const, origin: "top-level" as const } };
}

describe("findSkillCommand", () => {
	test("source:skillかつname:skill:<name>のエントリを返す", () => {
		const target = command("skill:ponder", "skill", "/path/to/SKILL.md");
		expect(findSkillCommand([target], "ponder")).toBe(target);
	});

	test("同名でもsourceがskill以外のエントリは対象外", () => {
		const extensionCommand = command("skill:ponder", "extension", "/path/to/extension.ts");
		const promptCommand = command("skill:ponder", "prompt", "/path/to/prompt.md");
		expect(findSkillCommand([extensionCommand, promptCommand], "ponder")).toBeUndefined();
	});

	test("該当エントリが無い場合はundefinedを返す", () => {
		expect(findSkillCommand([], "ponder")).toBeUndefined();
	});

	test("該当エントリが複数ある場合は配列の最初の要素を返す", () => {
		const first = command("skill:ponder", "skill", "/first/SKILL.md");
		const second = command("skill:ponder", "skill", "/second/SKILL.md");
		expect(findSkillCommand([first, second], "ponder")).toBe(first);
	});
});
