import { describe, expect, test } from "bun:test";
import { feedNdjsonChunk } from "./ndjson.ts";

describe("feedNdjsonChunk", () => {
	test("1チャンクに複数行あれば全て行として返す", () => {
		expect(feedNdjsonChunk("", "a\nb\nc\n")).toEqual({ lines: ["a", "b", "c"], pending: "" });
	});
});
