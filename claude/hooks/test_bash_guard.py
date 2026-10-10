import importlib.util
import json
import os
import subprocess
import sys
import unittest

HOOK_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bash-guard.py")

# ファイル名にハイフンがあり通常のimportができないためパスで読み込む
_spec = importlib.util.spec_from_file_location("bash_guard", HOOK_PATH)
bash_guard = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(bash_guard)


def run_hook(stdin_text):
    proc = subprocess.run(
        [sys.executable, HOOK_PATH],
        input=stdin_text,
        capture_output=True,
        text=True,
    )
    return proc.returncode, proc.stdout


def bash_payload(command):
    return json.dumps({"tool_name": "Bash", "tool_input": {"command": command}})


def verdict(command):
    """フック全体を通した判定。'deny' / 'ask' / None を返す。"""
    code, out = run_hook(bash_payload(command))
    assert code == 0, "exit code %s" % code
    if not out.strip():
        return None
    data = json.loads(out)["hookSpecificOutput"]
    assert data["hookEventName"] == "PreToolUse"
    assert data["permissionDecisionReason"]
    return data["permissionDecision"]


class EndToEndTest(unittest.TestCase):
    def test_git_push_is_denied(self):
        self.assertEqual(verdict("git push"), "deny")

    def test_neutral_commands_have_no_opinion(self):
        for cmd in ["git status", "git commit -m x", "git log --grep push",
                    "ls", "", "docker ps", "docker compose ps",
                    "docker -H tcp://x ps", "gh pr view 1",
                    "gh pr list --json number"]:
            with self.subTest(cmd=cmd):
                self.assertIsNone(verdict(cmd))

    def test_non_bash_tool_has_no_opinion(self):
        payload = json.dumps({"tool_name": "Read",
                              "tool_input": {"command": "git push"}})
        self.assertEqual(run_hook(payload), (0, ""))


class RobustnessTest(unittest.TestCase):
    def assert_silent(self, stdin_text):
        self.assertEqual(run_hook(stdin_text), (0, ""))

    def test_empty_stdin(self):
        self.assert_silent("")

    def test_invalid_json(self):
        self.assert_silent("{not json")

    def test_missing_tool_input(self):
        self.assert_silent(json.dumps({"tool_name": "Bash"}))

    def test_non_dict_json(self):
        self.assert_silent("[1, 2]")

    def test_non_string_command(self):
        self.assert_silent(json.dumps(
            {"tool_name": "Bash", "tool_input": {"command": 5}}))


class VerdictCase(unittest.TestCase):
    def assert_verdicts(self, expected, commands):
        for cmd in commands:
            with self.subTest(cmd=cmd):
                self.assertEqual(verdict(cmd), expected)


class GitTest(VerdictCase):
    def test_push_with_global_options_and_wrappers_is_denied(self):
        self.assert_verdicts("deny", [
            "git -C . push",
            "git -c x=y push origin main",
            "git --git-dir=.git push",
            "git --git-dir .git push",
            "git --no-pager push",
            "/usr/bin/git push",
            "FOO=1 git push",
            "env git push",
            "env -u HOME git push",
            "sudo -u me git push",
            "command git push",
            "time nohup git push",
        ])

    def test_push_in_nested_or_compound_commands_is_denied(self):
        self.assert_verdicts("deny", [
            "bash -c 'git push'",
            "sh -c \"git push\"",
            "zsh -c 'ls; git push'",
            "bash -lc 'git push'",
            "echo $(git push)",
            "echo \"$(git push)\"",
            "echo `git push`",
            "ls && git push",
            "ls | git push",
            "ls\ngit push",
            "(git push)",
            "bash -c \"bash -c 'git push'\"",
        ])

    def test_quoted_push_text_is_not_a_command(self):
        self.assert_verdicts(None, [
            "echo 'git push'",
            "git commit -m 'git push later'",
            "echo a\\ git push",
        ])

    def test_commit_that_skips_hooks_is_denied(self):
        self.assert_verdicts("deny", [
            "git commit --no-verify",
            "git commit -m x --no-verify",
            "git commit -nm x",
            "git commit -n -m x",
            "git -c core.hooksPath=/dev/null commit -m x",
            "git -c core.hookspath=/dev/null push",
        ])

    def test_ordinary_commit_and_read_only_commands_pass(self):
        self.assert_verdicts(None, [
            "git commit -am x",
            "git commit --amend --no-edit",
            "git -C sub status",
            "git -c user.name=x log",
            "git diff --name-only",
        ])


class DockerTest(VerdictCase):
    def test_mutating_subcommands_ask_even_after_global_options(self):
        self.assert_verdicts("ask", [
            "docker run x",
            "docker -H tcp://x run x",
            "docker --host=tcp://x run x",
            "docker --context c exec x",
            "docker -l debug rm x",
            "docker compose -f x.yml up",
            "docker compose --profile p run x",
            "docker compose -p n down",
            "docker --context c compose --env-file e up -d",
            "docker-compose up",
            "docker-compose ps",
            "sudo docker run x",
        ])

    def test_read_only_subcommands_pass(self):
        self.assert_verdicts(None, [
            "docker ps",
            "docker images",
            "docker logs x",
            "docker inspect x",
            "docker version",
            "docker compose ps",
            "docker compose -f x.yml logs",
            "docker -H tcp://x ps",
            "docker",
        ])


class GhTest(VerdictCase):
    def test_credential_and_extension_groups_are_denied(self):
        self.assert_verdicts("deny", [
            "gh auth token",
            "gh ssh-key add",
            "gh gpg-key list",
            "gh extension install x",
            "gh extensions list",
            "gh -R o/r auth status",
        ])

    def test_unlisted_subcommands_ask_by_default(self):
        self.assert_verdicts("ask", [
            "gh pr create",
            "gh pr merge 1",
            "gh release delete v1",
            "gh repo edit",
            "gh new-subcommand-xyz",
            "gh api repos/x",
            "gh -R o/r pr create",
            "gh pr -R o/r comment 1",
        ])

    def test_read_only_subcommands_pass(self):
        self.assert_verdicts(None, [
            "gh pr view 1",
            "gh pr list --json number",
            "gh -R o/r pr diff 1",
            "gh pr checks",
            "gh issue list",
            "gh repo view",
            "gh run view 1",
            "gh release list",
            "gh workflow view x",
            "gh search prs foo",
            "gh status",
            "gh browse",
            "gh --version",
            "gh help",
            "gh cache list",
            "gh ruleset check",
            "gh codespace view",
            "gh",
        ])


class SegmentTest(VerdictCase):
    def test_strictest_segment_wins(self):
        self.assert_verdicts("ask", ["git status && docker run x"])
        self.assert_verdicts("deny", [
            "git push; docker run x",
            "docker run x; git push",
        ])

    def test_unparsable_command_asks_only_when_a_tool_word_appears(self):
        self.assert_verdicts("ask", ['gh "pr', "echo 'unterminated; git"])
        self.assert_verdicts(None, ['echo "unterminated', "echo 'x"])

    def test_redirects_are_not_separators(self):
        self.assert_verdicts(None, ["git status 2>&1", "docker ps > out.txt"])
        self.assert_verdicts("deny", ["git push 2>&1"])


if __name__ == "__main__":
    unittest.main()
