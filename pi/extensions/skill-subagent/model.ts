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
