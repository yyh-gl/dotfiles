export interface SkillInvocation {
	skillName: string;
	args: string;
}

const SKILL_PREFIX = "/skill:";

export function parseSkillInvocation(text: string): SkillInvocation | undefined {
	if (!text.startsWith(SKILL_PREFIX)) return undefined;
	const rest = text.slice(SKILL_PREFIX.length);
	const spaceIndex = rest.indexOf(" ");
	if (spaceIndex === -1) return { skillName: rest, args: "" };
	return { skillName: rest.slice(0, spaceIndex), args: rest.slice(spaceIndex + 1).trim() };
}
