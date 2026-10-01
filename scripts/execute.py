#!/usr/bin/env python3
"""steps/*.md を順番に claude -p で実行する。push はしない (diff を確認して手動で push)。

使い方: python3 scripts/execute.py steps/01_xxx.md [steps/02_yyy.md ...]
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

ALLOWED_TOOLS = [
    "Read", "Edit", "Write",
    "Bash(git status)", "Bash(git diff *)", "Bash(git add *)", "Bash(git commit *)",
    "Bash(docker compose exec -T web bundle exec rspec *)",
    "Bash(docker compose exec -T web bin/rails *)",
]


def load_guardrails() -> str:
    # CLAUDE.md は claude が自動で読むので含めない。docs は step 内のパス指定で必要時に読ませる。
    harness = ROOT / "docs" / "harness.md"
    return harness.read_text() if harness.exists() else ""


def run_step(step: Path) -> int:
    prompt = f"{load_guardrails()}\n\n# Step: {step.name}\n\n{step.read_text()}"
    cmd = [
        "claude", "-p", prompt,
        "--model", "sonnet",
        "--allowedTools", *ALLOWED_TOOLS,
    ]
    return subprocess.run(cmd, cwd=ROOT).returncode


def main() -> int:
    steps = [Path(a) for a in sys.argv[1:]]
    if not steps:
        print(__doc__)
        return 1
    for step in steps:
        print(f"==> {step}")
        if run_step(step) != 0:
            print(f"FAILED: {step}", file=sys.stderr)
            return 1
    print("完了。git diff を確認してから、手動で push してください。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
