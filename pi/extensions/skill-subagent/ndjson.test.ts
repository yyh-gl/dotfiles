import { describe, expect, test } from "bun:test";
import { createBufferDecoder, feedNdjsonChunk, parseNdjsonLine } from "./ndjson.ts";

describe("feedNdjsonChunk", () => {
	test("1チャンクに複数行あれば全て行として返す", () => {
		expect(feedNdjsonChunk("", "a\nb\nc\n")).toEqual({ lines: ["a", "b", "c"], pending: "" });
	});

	test("末尾に改行がないチャンクは未完了分がpendingに残る", () => {
		expect(feedNdjsonChunk("", "a\nb")).toEqual({ lines: ["a"], pending: "b" });
	});

	test("前回のpendingと新規チャンクが結合して1行になる", () => {
		expect(feedNdjsonChunk("abc", "def\n")).toEqual({ lines: ["abcdef"], pending: "" });
	});

	test("空文字チャンクはlinesが空でpendingも変化しない", () => {
		expect(feedNdjsonChunk("abc", "")).toEqual({ lines: [], pending: "abc" });
	});

	test("改行のみのチャンクは空文字列の行を1つ生成する", () => {
		expect(feedNdjsonChunk("", "\n")).toEqual({ lines: [""], pending: "" });
	});

	test("複数回に分けてすべて未完了のまま蓄積される", () => {
		const first = feedNdjsonChunk("", "ab");
		expect(first).toEqual({ lines: [], pending: "ab" });
		const second = feedNdjsonChunk(first.pending, "cd");
		expect(second).toEqual({ lines: [], pending: "abcd" });
	});

	test("非常に長い1行が複数チャンクに渡って正しく1行として完成する", () => {
		const longPart = "x".repeat(10000);
		const first = feedNdjsonChunk("", longPart);
		const second = feedNdjsonChunk(first.pending, `${longPart}\n`);
		expect(second).toEqual({ lines: [longPart + longPart], pending: "" });
	});

	test("JSON文字列値中のエスケープされた改行では分割されず1行として保持される", () => {
		expect(feedNdjsonChunk("", '{"text":"a\\nb"}\n')).toEqual({ lines: ['{"text":"a\\nb"}'], pending: "" });
	});
});

describe("createBufferDecoder", () => {
	test("マルチバイト文字の生バイト列がチャンク境界で分割されても正しく復元される", () => {
		const text = "こんにちは";
		const raw = Buffer.from(text, "utf-8");
		const splitAt = 7;
		const decode = createBufferDecoder();

		const result = decode(raw.subarray(0, splitAt)) + decode(raw.subarray(splitAt));

		expect(result).toBe(text);
	});
});

describe("parseNdjsonLine", () => {
	test("妥当なJSON行はパース結果のオブジェクトを返す", () => {
		expect(parseNdjsonLine('{"type":"response"}')).toEqual({ type: "response" });
	});

	test("不正なJSON文字列は例外を投げずundefinedを返す", () => {
		expect(parseNdjsonLine("{not json")).toBeUndefined();
	});

	test("空文字列の行はundefinedを返す", () => {
		expect(parseNdjsonLine("")).toBeUndefined();
	});

	test("空白・タブのみの行はundefinedを返す", () => {
		expect(parseNdjsonLine("  \t ")).toBeUndefined();
	});
});
