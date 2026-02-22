# /// script
# requires-python = ">=3.9"
# ///
"""Cross-repo Bon survey — scans all .bon/ directories under ~/Repos and produces
a summary of open outcomes and actions, grouped by repo.

Usage:
    uv run --script survey.py              # Human-readable overview
    uv run --script survey.py --json       # Machine-readable JSON
    uv run --script survey.py --markdown   # Markdown table
"""

import json
import os
import sys
from pathlib import Path


def load_items(bon_path: Path) -> list[dict]:
    items = {}
    with open(bon_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            item = json.loads(line)
            items[item["id"]] = item  # last wins (dedup)
    return list(items.values())


def survey(repos_dir: Path) -> list[dict]:
    results = []
    for entry in sorted(repos_dir.iterdir()):
        items_path = entry / ".bon" / "items.jsonl"
        if not items_path.exists():
            continue

        items = load_items(items_path)
        open_items = [i for i in items if i.get("status") == "open"]
        done_items = [i for i in items if i.get("status") == "done"]

        if not open_items and not done_items:
            continue

        outcomes = [i for i in open_items if i["type"] == "outcome"]
        actions = [i for i in open_items if i["type"] == "action"]
        waiting = [i for i in open_items if i.get("waiting_for")]

        results.append({
            "repo": entry.name,
            "open": len(open_items),
            "done": len(done_items),
            "outcomes": outcomes,
            "actions": actions,
            "waiting": waiting,
        })

    results.sort(key=lambda r: r["open"], reverse=True)
    return results


def print_text(results: list[dict]) -> None:
    total_open = sum(r["open"] for r in results)
    total_done = sum(r["done"] for r in results)
    active_repos = [r for r in results if r["open"] > 0]

    print(f"Bon Survey — {total_open} open across {len(active_repos)} repos ({total_done} done)\n")

    for r in results:
        if r["open"] == 0:
            continue

        print(f"{'─' * 60}")
        print(f"{r['repo']}  ({r['open']} open, {r['done']} done)")
        print(f"{'─' * 60}")

        # Group actions under their parent outcomes
        outcome_ids = {o["id"] for o in r["outcomes"]}
        orphan_actions = [a for a in r["actions"] if a.get("parent") not in outcome_ids]

        for outcome in r["outcomes"]:
            children = [a for a in r["actions"] if a.get("parent") == outcome["id"]]
            w = " [WAITING]" if outcome.get("waiting_for") else ""
            print(f"  ○ {outcome['title']}{w}")
            for child in children:
                cw = " [WAITING]" if child.get("waiting_for") else ""
                print(f"    · {child['title']}{cw}")

        for action in orphan_actions:
            w = " [WAITING]" if action.get("waiting_for") else ""
            print(f"  · {action['title']}{w}")

        print()


def print_markdown(results: list[dict]) -> None:
    total_open = sum(r["open"] for r in results)
    active_repos = [r for r in results if r["open"] > 0]

    print(f"# Bon Survey — {total_open} open across {len(active_repos)} repos\n")
    print(f"| Repo | Open | Done | Outcomes | Actions | Waiting |")
    print(f"|------|------|------|----------|---------|---------|")
    for r in results:
        if r["open"] == 0:
            continue
        print(f"| {r['repo']} | {r['open']} | {r['done']} | {len(r['outcomes'])} | {len(r['actions'])} | {len(r['waiting'])} |")

    print()
    for r in results:
        if r["open"] == 0:
            continue
        print(f"\n## {r['repo']}\n")
        outcome_ids = {o["id"] for o in r["outcomes"]}
        orphan_actions = [a for a in r["actions"] if a.get("parent") not in outcome_ids]

        for outcome in r["outcomes"]:
            children = [a for a in r["actions"] if a.get("parent") == outcome["id"]]
            print(f"- **{outcome['title']}**")
            for child in children:
                w = " *(waiting)*" if child.get("waiting_for") else ""
                print(f"  - {child['title']}{w}")

        for action in orphan_actions:
            w = " *(waiting)*" if action.get("waiting_for") else ""
            print(f"- {action['title']}{w}")


def print_json(results: list[dict]) -> None:
    summary = []
    for r in results:
        if r["open"] == 0:
            continue
        summary.append({
            "repo": r["repo"],
            "open": r["open"],
            "done": r["done"],
            "outcomes": [{"id": o["id"], "title": o["title"]} for o in r["outcomes"]],
            "actions": [{"id": a["id"], "title": a["title"], "parent": a.get("parent")} for a in r["actions"]],
        })
    print(json.dumps(summary, indent=2))


def main():
    repos_dir = Path(os.environ.get("REPOS_DIR", Path.home() / "Repos"))
    results = survey(repos_dir)

    if "--json" in sys.argv:
        print_json(results)
    elif "--markdown" in sys.argv:
        print_markdown(results)
    else:
        print_text(results)


if __name__ == "__main__":
    main()
