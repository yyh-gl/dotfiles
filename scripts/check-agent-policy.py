#!/usr/bin/env python3
"""claude/managed-settings.jsonとcodex/*.tomlで揃えるべきsandbox・permissionsの差分を検出する。

対応関係はdocs/codex-sandbox.mdを参照。意図的な差分は下のINTENTIONALに理由つきで書く。
差分があればexit 1。
"""
import json
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
claude = json.loads((ROOT / "claude/managed-settings.json").read_text())
requirements = tomllib.loads((ROOT / "codex/requirements.toml").read_text())
managed = tomllib.loads((ROOT / "codex/managed_config.toml").read_text())

# Claudeにだけある（Codexに置かない）項目。理由はdocs/codex-sandbox.md
INTENTIONAL_CLAUDE_ONLY = {
    "allow_write": {"~/.claude/logs"},  # Claude専用のログ
    "bash": {
        "git -C * push*", "git -c * push*", "git --git-dir* push*", "git --work-tree* push*",
        "git commit*--no-verify*", "git commit* -n*",  # Codexは前方一致のため直後形だけ別に置く
        "docker -* *", "docker compose -* *",  # Codexのprefix_rulesは前置オプションを表現できない
    },
}

problems = []


def compare(label, claude_set, codex_set, claude_only=frozenset(), codex_only=frozenset()):
    for item in sorted(claude_set - codex_set - claude_only):
        problems.append(f"{label}: Claudeにだけある: {item}")
    for item in sorted(codex_set - claude_set - codex_only):
        problems.append(f"{label}: Codexにだけある: {item}")


sandbox = claude["sandbox"]
perms = claude["permissions"]

# ドメイン
compare("allowedDomains", set(sandbox["network"]["allowedDomains"]),
        set(requirements["experimental_network"]["domains"]))

# 環境変数
compare("envVars", {e["name"] for e in sandbox["credentials"]["envVars"]},
        set(managed["shell_environment_policy"]["exclude"]))

# 書き込み許可 / 書き込み禁止
codex_fs = requirements["permissions"]["dotfiles"]["filesystem"]
compare("allowWrite", set(sandbox["filesystem"]["allowWrite"]),
        {p for p, m in codex_fs.items() if m == "write"},
        claude_only=INTENTIONAL_CLAUDE_ONLY["allow_write"])
compare("denyWrite", set(sandbox["filesystem"].get("denyWrite", [])),
        {p for p, m in codex_fs.items() if m in ("read", "deny")})


# 読み取り禁止: credentials.filesとpermissions.denyのRead(...)をCodexのdeny_readの形に直して比べる
def to_codex_path(pattern):
    if pattern.endswith("/**") and pattern.startswith("~"):
        pattern = pattern[:-3]  # Codexはディレクトリを指せばよい
    if pattern.startswith("~"):
        return pattern
    if pattern.startswith("**/"):
        return "/" + pattern
    return "/**/" + pattern


claude_deny_read = {to_codex_path(r[5:-1]) for r in perms["deny"] if r.startswith("Read(")}
claude_deny_read |= {f["path"] for f in sandbox["credentials"]["files"]}
compare("deny_read", claude_deny_read, set(requirements["permissions"]["filesystem"]["deny_read"]))


# Bashコマンド: Claudeのdeny/askの前方一致パターンを、Codexのprefix_rulesのトークン列に直して比べる
def claude_tokens(rule):
    body = rule[5:-1]
    if body in INTENTIONAL_CLAUDE_ONLY["bash"]:
        return None
    body = body.rstrip("*").rstrip()
    return tuple(body.split())


claude_forbidden, claude_prompt = set(), set()
for rule in perms["deny"]:
    if rule.startswith("Bash("):
        t = claude_tokens(rule)
        if t:
            claude_forbidden.add(t)
for rule in perms["ask"]:
    if rule.startswith("Bash("):
        t = claude_tokens(rule)
        if t:
            claude_prompt.add(t)

codex_forbidden, codex_prompt = set(), set()
for rule in requirements["rules"]["prefix_rules"]:
    tokens = tuple(p["token"] for p in rule["pattern"])
    (codex_forbidden if rule["decision"] == "forbidden" else codex_prompt).add(tokens)

compare("forbidden(Bash)", claude_forbidden, codex_forbidden,
        codex_only={("git", "commit", "--no-verify"), ("git", "commit", "-n")})
compare("prompt(Bash)", claude_prompt, codex_prompt)

if problems:
    print("ClaudeとCodexの設定に差分があります。揃えるか、scripts/check-agent-policy.pyのINTENTIONALに理由つきで追加してください:")
    for p in problems:
        print(f"  - {p}")
    sys.exit(1)
print("ClaudeとCodexの設定に差分はありません")
