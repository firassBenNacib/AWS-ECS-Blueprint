#!/usr/bin/env python3
"""Helpers for constraining CLI-provided file paths to expected locations."""

from __future__ import annotations

import os
import tempfile
from pathlib import Path


def _dedupe(paths: list[Path]) -> list[Path]:
    seen: set[Path] = set()
    unique: list[Path] = []
    for path in paths:
        if path not in seen:
            unique.append(path)
            seen.add(path)
    return unique


def _candidate_roots(include_temp: bool = True) -> list[Path]:
    roots = [Path.cwd().resolve()]

    github_workspace = os.environ.get("GITHUB_WORKSPACE")
    if github_workspace:
        roots.append(Path(github_workspace).resolve())

    if include_temp:
        roots.append(Path(tempfile.gettempdir()).resolve())
        runner_temp = os.environ.get("RUNNER_TEMP")
        if runner_temp:
            roots.append(Path(runner_temp).resolve())

    return _dedupe(roots)


def _resolve_path(path: str) -> Path:
    candidate = Path(path).expanduser()
    if not candidate.is_absolute():
        candidate = Path.cwd() / candidate
    return candidate.resolve(strict=False)


def _is_within(path: Path, root: Path) -> bool:
    return path == root or path.is_relative_to(root)


def _ensure_allowed(path: Path, *, description: str, include_temp: bool) -> Path:
    allowed_roots = _candidate_roots(include_temp=include_temp)
    if any(_is_within(path, root) for root in allowed_roots):
        return path

    allowed_display = ", ".join(str(root) for root in allowed_roots)
    raise ValueError(f"{description} must stay within the repository workspace or runner temp paths: {allowed_display}")


def resolve_existing_file(path: str, *, description: str, include_temp: bool = True) -> Path:
    resolved = _ensure_allowed(_resolve_path(path), description=description, include_temp=include_temp)
    if not resolved.is_file():
        raise FileNotFoundError(f"{description} does not exist: {resolved}")
    return resolved


def resolve_existing_dir(path: str, *, description: str, include_temp: bool = True) -> Path:
    resolved = _ensure_allowed(_resolve_path(path), description=description, include_temp=include_temp)
    if not resolved.is_dir():
        raise FileNotFoundError(f"{description} does not exist: {resolved}")
    return resolved


def resolve_output_file(path: str, *, description: str, include_temp: bool = True) -> Path:
    resolved = _resolve_path(path)
    parent = resolved.parent.resolve(strict=False)
    _ensure_allowed(parent, description=f"{description} parent directory", include_temp=include_temp)
    if not parent.exists():
        raise FileNotFoundError(f"{description} parent directory does not exist: {parent}")
    return resolved


def resolve_github_output_file(path: str) -> Path:
    resolved = resolve_output_file(path, description="GitHub output file")
    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        expected = _resolve_path(github_output)
        if resolved != expected:
            raise ValueError(f"GitHub output path must match GITHUB_OUTPUT ({expected}), got {resolved}")
    return resolved
