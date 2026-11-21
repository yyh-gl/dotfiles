export interface NdjsonFeedResult {
	lines: string[];
	pending: string;
}

export function feedNdjsonChunk(pending: string, chunk: string): NdjsonFeedResult {
	const combined = pending + chunk;
	const lines = combined.split("\n");
	const newPending = lines.pop() ?? "";
	return { lines, pending: newPending };
}
