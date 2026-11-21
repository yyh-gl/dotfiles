import { describe, expect, test } from "bun:test";
import { findSkillCommand } from "./commands.ts";

describe("findSkillCommand", () => {
	test("source:skillかつname:skill:<name>のエントリを返す", () => {
		const target = {
			name: "skill:ponder",
			source: "skill" as const,
			sourceInfo: { path: "/path/to/SKILL.md", source: "skill", scope: "project" as const, origin: "top-level" as const },
		};
		expect(findSkillCommand([target], "ponder")).toBe(target);
	});
});
