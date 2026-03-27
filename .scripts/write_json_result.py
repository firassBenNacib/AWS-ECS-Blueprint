#!/usr/bin/env python3
"""Write a JSON object to disk from CLI key/value arguments."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--set", dest="string_fields", action="append", nargs=2, metavar=("KEY", "VALUE"), default=[])
    parser.add_argument(
        "--set-nullable-string",
        dest="nullable_string_fields",
        action="append",
        nargs=2,
        metavar=("KEY", "VALUE"),
        default=[],
    )
    parser.add_argument("--set-int", dest="int_fields", action="append", nargs=2, metavar=("KEY", "VALUE"), default=[])
    parser.add_argument(
        "--set-nullable-float",
        dest="nullable_float_fields",
        action="append",
        nargs=2,
        metavar=("KEY", "VALUE"),
        default=[],
    )
    parser.add_argument(
        "--set-nullable-int",
        dest="nullable_int_fields",
        action="append",
        nargs=2,
        metavar=("KEY", "VALUE"),
        default=[],
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload: dict[str, object] = {}

    for key, value in args.string_fields:
        payload[key] = value

    for key, value in args.nullable_string_fields:
        payload[key] = None if value == "null" else value

    for key, value in args.int_fields:
        payload[key] = int(value)

    for key, value in args.nullable_float_fields:
        payload[key] = None if value == "null" else float(value)

    for key, value in args.nullable_int_fields:
        payload[key] = None if value == "null" else int(value)

    Path(args.output).write_text(json.dumps(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
