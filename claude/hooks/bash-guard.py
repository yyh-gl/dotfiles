#!/usr/bin/env python3
import json
import os
import re
import shlex
import sys

NONE, ASK, DENY = 0, 1, 2
DECISION_NAME = {ASK: "ask", DENY: "deny"}
MAX_DEPTH = 5

SEPARATOR_CHARS = set(";&|()")
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
TOOL_WORDS = re.compile(r"\b(gh|docker|git)\b")
SHELLS = {"bash", "sh", "zsh"}

# ラッパー名 -> 値を取るオプション
WRAPPERS = {
    "env": {"-u", "--unset", "-C", "--chdir", "-S", "--split-string"},
    "command": set(),
    "time": set(),
    "nohup": set(),
    "exec": {"-a"},
    "builtin": set(),
    "sudo": {"-u", "--user", "-g", "--group", "-h", "--host", "-p", "--prompt",
             "-C", "-D", "--chdir", "-R", "--chroot", "-T", "-U", "-r", "-t"},
    "nice": {"-n", "--adjustment"},
}

GIT_VALUE_OPTIONS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace",
                     "--exec-path", "--config-env"}

DOCKER_VALUE_OPTIONS = {"-H", "--host", "--context", "-c", "--config", "-l",
                        "--log-level", "--tlscacert", "--tlscert", "--tlskey"}
DOCKER_ASK = set("""run exec cp build buildx builder create start restart stop
kill rm rmi update commit pull push login logout tag save load import export
container image volume network plugin context system swarm service stack node
secret config trust manifest""".split())
COMPOSE_VALUE_OPTIONS = {"-f", "--file", "-p", "--project-name", "--profile",
                         "--env-file", "--project-directory", "--ansi",
                         "--parallel", "--progress"}
COMPOSE_ASK = set("""up down run exec cp build create start stop restart rm kill
pull push watch""".split())

GH_VALUE_OPTIONS = {"-R", "--repo"}
GH_DENY_GROUPS = {"auth", "ssh-key", "gpg-key", "extension", "extensions"}
# 読み取り専用と確認できたものだけを許す。未知のサブコマンドは既定でask
GH_READ_ONLY = {
    "pr": {"view", "list", "diff", "checks", "status"},
    "issue": {"view", "list", "status"},
    "repo": {"view", "list"},
    "run": {"list", "view"},
    "release": {"list", "view"},
    "workflow": {"list", "view"},
    "cache": {"list"},
    "label": {"list"},
    "variable": {"list"},
    "secret": {"list"},
    "ruleset": {"list", "view", "check"},
    "codespace": {"list", "view"},
}
GH_READ_ONLY_GROUPS = {"search", "status", "browse", "version", "help"}
GH_READ_ONLY_FLAGS = {"--version", "--help", "-h"}


def split_unquoted_newlines(command):
    # shlexは改行を空白として扱うため、クォート外の改行だけ;に置き換えて区間を分ける
    out = []
    quote = None
    escaped = False
    for ch in command:
        if escaped:
            escaped = False
        elif ch == "\\" and quote != "'":
            escaped = True
        elif quote:
            if ch == quote:
                quote = None
        elif ch in "'\"":
            quote = ch
        elif ch == "\n":
            ch = ";"
        out.append(ch)
    return "".join(out)


def extract_substitutions(command):
    found = []
    for m in re.finditer(r"`([^`]*)`", command):
        found.append(m.group(1))
    i = 0
    while True:
        i = command.find("$(", i)
        if i < 0:
            break
        depth = 0
        j = i + 1
        while j < len(command):
            if command[j] == "(":
                depth += 1
            elif command[j] == ")":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        found.append(command[i + 2:j])
        i += 2
    return found


def tokenize_segments(command):
    lex = shlex.shlex(split_unquoted_newlines(command), posix=True,
                      punctuation_chars=True)
    lex.whitespace_split = True
    segments = [[]]
    for token in lex:
        if is_separator(token):
            segments.append([])
        else:
            segments[-1].append(token)
    return [s for s in segments if s]


def is_separator(token):
    if not token or not set(token) <= set(";&|()<>"):
        return False
    if token[0] in "<>" and "(" not in token:
        return False
    return True


def strip_wrappers(tokens):
    i = 0
    while i < len(tokens):
        token = tokens[i]
        name = os.path.basename(token)
        if ASSIGNMENT.match(token):
            i += 1
        elif name in WRAPPERS:
            value_options = WRAPPERS[name]
            i += 1
            while i < len(tokens) and tokens[i].startswith("-"):
                i += 2 if tokens[i] in value_options else 1
        else:
            break
    return tokens[i:]


def skip_global_options(args, value_options):
    i = 0
    while i < len(args) and args[i].startswith("-"):
        if args[i] in value_options:
            i += 1
        i += 1
    return args[:i], args[i:]


def judge_git(args):
    options, rest = skip_global_options(args, GIT_VALUE_OPTIONS)
    if not rest:
        return NONE, ""
    sub, sub_args = rest[0], rest[1:]
    hooks_path_overridden = any("core.hookspath" in o.lower() for o in options)
    if sub == "push":
        return DENY, "git pushは人間が行う"
    if sub == "commit":
        if hooks_path_overridden:
            return DENY, "core.hooksPathを上書きしてhookを飛ばさない"
        if any(a == "--no-verify" or re.match(r"^-[A-Za-z]*n[A-Za-z]*$", a)
               for a in sub_args):
            return DENY, "git commitで--no-verify（-n）を使ってhookを飛ばさない"
    return NONE, ""


def judge_docker(args):
    _, rest = skip_global_options(args, DOCKER_VALUE_OPTIONS)
    if not rest:
        return NONE, ""
    sub = rest[0]
    if sub == "compose":
        _, compose_rest = skip_global_options(rest[1:], COMPOSE_VALUE_OPTIONS)
        if compose_rest and compose_rest[0] in COMPOSE_ASK:
            return ASK, "docker compose %sは確認が必要" % compose_rest[0]
        return NONE, ""
    if sub in DOCKER_ASK:
        return ASK, "docker %sは確認が必要" % sub
    return NONE, ""


def judge_gh(args):
    positional = []
    i = 0
    while i < len(args) and len(positional) < 2:
        arg = args[i]
        if arg in GH_READ_ONLY_FLAGS:
            return NONE, ""
        if arg in GH_VALUE_OPTIONS:
            i += 1
        elif not arg.startswith("-"):
            positional.append(arg)
        i += 1
    if not positional:
        return NONE, ""
    group = positional[0]
    sub = positional[1] if len(positional) > 1 else None
    if group in GH_DENY_GROUPS:
        return DENY, "gh %sは認証情報・拡張を扱うため実行しない" % group
    if group in GH_READ_ONLY_GROUPS:
        return NONE, ""
    if sub in GH_READ_ONLY.get(group, ()):
        return NONE, ""
    return ASK, "gh %s %sは読み取り専用と確認できないため確認が必要" % (group, sub or "")


def judge_segment(tokens, depth):
    tokens = strip_wrappers(tokens)
    if not tokens:
        return NONE, ""
    name = os.path.basename(tokens[0])
    args = tokens[1:]
    if name in SHELLS:
        return judge_shell(args, depth)
    if name == "git":
        return judge_git(args)
    if name == "docker":
        return judge_docker(args)
    if name == "docker-compose":
        return ASK, "docker-composeは確認が必要"
    if name == "gh":
        return judge_gh(args)
    return NONE, ""


def judge_shell(args, depth):
    for i, arg in enumerate(args):
        if not arg.startswith("-") or arg.startswith("--"):
            break
        if "c" in arg and i + 1 < len(args):
            return judge(args[i + 1], depth + 1)
    return NONE, ""


def worst(results):
    best = (NONE, "")
    for result in results:
        if result[0] > best[0]:
            best = result
    return best


def judge(command, depth=0):
    if depth > MAX_DEPTH:
        return unparsable(command)
    try:
        segments = tokenize_segments(command)
    except ValueError:
        return unparsable(command)
    results = [judge_segment(s, depth) for s in segments]
    results += [judge(inner, depth + 1) for inner in extract_substitutions(command)]
    return worst(results)


def unparsable(command):
    if TOOL_WORDS.search(command):
        return ASK, "コマンドを解析できず、gh・docker・gitを含むため確認が必要"
    return NONE, ""


def decide(data):
    if not isinstance(data, dict) or data.get("tool_name") != "Bash":
        return NONE, ""
    tool_input = data.get("tool_input")
    command = tool_input.get("command") if isinstance(tool_input, dict) else None
    if not isinstance(command, str):
        return NONE, ""
    return judge(command)


def main():
    # 締める専用のフックなので、失敗時にClaude Code本体を止めるより意見なしで終える方を選ぶ
    try:
        level, reason = decide(json.load(sys.stdin))
        if level:
            print(json.dumps({"hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": DECISION_NAME[level],
                "permissionDecisionReason": reason,
            }}, ensure_ascii=False))
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
