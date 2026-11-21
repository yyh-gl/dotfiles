import type { SlashCommandInfo } from "@earendil-works/pi-coding-agent";

export function findSkillCommand(commands: SlashCommandInfo[], skillName: string): SlashCommandInfo | undefined {
	return commands.find((c) => c.source === "skill" && c.name === `skill:${skillName}`);
}
