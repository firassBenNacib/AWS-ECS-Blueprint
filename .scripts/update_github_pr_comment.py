#!/usr/bin/env python3
"""Create or update a sticky pull request comment."""

from __future__ import annotations

import argparse
import json
import os
import urllib.error
import urllib.request
from pathlib import Path


API_BASE = "https://api.github.com"


def api_request(method: str, url: str, token: str, payload: dict | None = None) -> dict | list:
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "User-Agent": "aws-terraform-template-ci",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    data = None
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            body = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed: {exc.code} {detail}") from exc
    return json.loads(body) if body else {}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True)
    parser.add_argument("--pr-number", required=True, type=int)
    parser.add_argument("--marker", required=True)
    parser.add_argument("--body-file", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        raise RuntimeError("GITHUB_TOKEN is required")

    body = Path(args.body_file).read_text()
    comments_url = f"{API_BASE}/repos/{args.repo}/issues/{args.pr_number}/comments?per_page=100"
    comments = api_request("GET", comments_url, token)

    existing_comment = None
    for comment in comments:
        if args.marker in comment.get("body", ""):
            existing_comment = comment
            break

    if existing_comment:
        api_request(
            "PATCH",
            f"{API_BASE}/repos/{args.repo}/issues/comments/{existing_comment['id']}",
            token,
            {"body": body},
        )
        print(f"Updated PR comment {existing_comment['id']}")
    else:
        created = api_request(
            "POST",
            f"{API_BASE}/repos/{args.repo}/issues/{args.pr_number}/comments",
            token,
            {"body": body},
        )
        print(f"Created PR comment {created['id']}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
