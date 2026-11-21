export interface SubagentPromptInput {
	baseDir: string;
	body: string;
	args: string;
}

export function buildSubagentPrompt({ baseDir, body, args }: SubagentPromptInput): string {
	const skillBlock = `References are relative to ${baseDir}.\n\n${body.trim()}`;
	return args.trim() ? `${skillBlock}\n\n${args}` : skillBlock;
}
