export interface NdjsonFeedResult {
	lines: string[];
	pending: string;
}

export function parseNdjsonLine(line: string): unknown | undefined {
	if (!line.trim()) return undefined;
	try {
		return JSON.parse(line);
	} catch {
		return undefined;
	}
}

export function feedNdjsonChunk(pending: string, chunk: string): NdjsonFeedResult {
	const combined = pending + chunk;
	const lines = combined.split("\n");
	const newPending = lines.pop() ?? "";
	return { lines, pending: newPending };
}
