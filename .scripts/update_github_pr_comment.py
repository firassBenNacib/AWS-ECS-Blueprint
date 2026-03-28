#!/usr/bin/env python3
"""Create or update a sticky pull request comment."""

from __future__ import annotations

import argparse
import http.client
import json
import os
import re
from typing import Any

from path_safety import resolve_existing_file


JsonObject = dict[str, Any]
JsonList = list[JsonObject]
REPO_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")


def api_request(method: str, path: str, token: str, payload: dict[str, Any] | None = None) -> JsonObject | JsonList:
    if not path.startswith("/repos/"):
        raise ValueError(f"Only GitHub repository API requests are allowed, got {path}")
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

    connection = http.client.HTTPSConnection("api.github.com")
    try:
        connection.request(method, path, body=data, headers=headers)
        response = connection.getresponse()
        body = response.read().decode("utf-8")
        if response.status >= 400:
            raise RuntimeError(f"{method} {path} failed: {response.status} {body}")
    finally:
        connection.close()
    return json.loads(body) if body else {}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pr-number", required=True, type=int)
    parser.add_argument("--marker", required=True)
    parser.add_argument("--body-file", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        raise RuntimeError("GITHUB_TOKEN is required")
    repo = os.environ.get("GITHUB_REPOSITORY")
    if not repo or not REPO_PATTERN.fullmatch(repo):
        raise RuntimeError("GITHUB_REPOSITORY must be set to owner/repo")

    body = resolve_existing_file(args.body_file, description="PR comment body file", include_temp=False).read_text(encoding="utf-8")
    comments_url = f"/repos/{repo}/issues/{args.pr_number}/comments?per_page=100"
    comments_response = api_request("GET", comments_url, token)
    if not isinstance(comments_response, list):
        raise RuntimeError(f"Expected a list response from GitHub comments API, got {type(comments_response).__name__}")
    comments = comments_response

    existing_comment = None
    for comment in comments:
        if args.marker in comment.get("body", ""):
            existing_comment = comment
            break

    if existing_comment:
        api_request(
            "PATCH",
            f"/repos/{repo}/issues/comments/{existing_comment['id']}",
            token,
            {"body": body},
        )
        print(f"Updated PR comment {existing_comment['id']}")
    else:
        created_response = api_request(
            "POST",
            f"/repos/{repo}/issues/{args.pr_number}/comments",
            token,
            {"body": body},
        )
        if not isinstance(created_response, dict):
            raise RuntimeError(f"Expected an object response when creating a PR comment, got {type(created_response).__name__}")
        created = created_response
        print(f"Created PR comment {created['id']}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
