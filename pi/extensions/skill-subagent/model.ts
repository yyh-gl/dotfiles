const THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const;

export type ThinkingLevelValue = (typeof THINKING_LEVELS)[number];

export function isValidThinkingLevel(value: unknown): value is ThinkingLevelValue {
	return typeof value === "string" && (THINKING_LEVELS as readonly string[]).includes(value);
}

export interface ModelReference {
	provider: string;
	modelId: string;
}

export function splitModelReference(value: unknown): ModelReference | undefined {
	if (typeof value !== "string") return undefined;
	const slashIndex = value.indexOf("/");
	if (slashIndex === -1) return undefined;
	const provider = value.slice(0, slashIndex);
	const modelId = value.slice(slashIndex + 1);
	if (!provider || !modelId) return undefined;
	return { provider, modelId };
}
