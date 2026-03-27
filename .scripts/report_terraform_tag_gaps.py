#!/usr/bin/env python3
import argparse
import collections
import json
import sys


def load_document(path: str):
    if path == "-":
        return json.load(sys.stdin)

    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def iter_child_modules(module):
    yield module
    for child in module.get("child_modules", []):
        yield from iter_child_modules(child)


def classify_tag_status(values, unknowns=None):
    unknowns = unknowns or {}
    has_tags = "tags" in values
    has_tags_all = "tags_all" in values

    if has_tags_all:
        if isinstance(values.get("tags_all"), dict) and values["tags_all"]:
            return "tagged", None
        if unknowns.get("tags_all"):
            return "unknown", "tags_all is unknown at plan time"
        if values.get("tags_all") in ({}, None):
            return "empty", "tags_all is empty"

    if has_tags:
        if isinstance(values.get("tags"), dict) and values["tags"]:
            return "tagged", None
        if unknowns.get("tags"):
            return "unknown", "tags is unknown at plan time"
        if values.get("tags") in ({}, None):
            return "empty", "tags is empty"

    return "unsupported", "resource type does not expose tags or tags_all"


def collect_plan_findings(document):
    findings = []

    for change in document.get("resource_changes", []):
        if change.get("mode") != "managed":
            continue
        if not str(change.get("type", "")).startswith("aws_"):
            continue

        actions = change.get("change", {}).get("actions", [])
        if actions == ["delete"]:
            continue

        after = change.get("change", {}).get("after") or {}
        after_unknown = change.get("change", {}).get("after_unknown") or {}
        status, reason = classify_tag_status(after, after_unknown)
        findings.append(
            {
                "address": change["address"],
                "type": change["type"],
                "status": status,
                "reason": reason,
            }
        )

    return findings


def collect_state_findings(document):
    findings = []
    root_module = document.get("values", {}).get("root_module")
    if not root_module:
        return findings

    for module in iter_child_modules(root_module):
        for resource in module.get("resources", []):
            if resource.get("mode") != "managed":
                continue
            if not str(resource.get("type", "")).startswith("aws_"):
                continue

            values = resource.get("values") or {}
            status, reason = classify_tag_status(values)
            findings.append(
                {
                    "address": resource["address"],
                    "type": resource["type"],
                    "status": status,
                    "reason": reason,
                }
            )

    return findings


def print_report(findings, source, fail_on_missing_tags=False, verbose_unsupported=False):
    totals = {
        "tagged": 0,
        "empty": 0,
        "unsupported": 0,
        "unknown": 0,
    }

    for finding in findings:
        totals[finding["status"]] += 1

    print("Terraform tag coverage report")
    print(f"Source: {source}")
    print(f"AWS resources scanned: {len(findings)}")
    print(f"Tagged: {totals['tagged']}")
    print(f"Missing tag values: {totals['empty']}")
    print(f"Unsupported for tagging: {totals['unsupported']}")
    print(f"Unknown at plan time: {totals['unknown']}")

    if not findings:
        print("")
        print("No managed AWS resources were found in the loaded Terraform document.")
        if source.startswith("state:"):
            print("This usually means the selected state is empty or the backend did not load any resources for this working directory.")
            print("If this root was intentionally destroyed, that empty-state result is expected.")
            print("Use the plan report when you want pre-deploy tag coverage for a currently destroyed root.")
        return 0

    untagged = [finding for finding in findings if finding["status"] == "empty"]
    unsupported = [finding for finding in findings if finding["status"] == "unsupported"]
    unknowns = [finding for finding in findings if finding["status"] == "unknown"]

    if not untagged:
        print("")
        print("All taggable AWS resources in this document receive tags.")
        if unsupported:
            print("Unsupported resource types are informational only and do not affect the result.")

    if unknowns:
        print("")
        print("Resources with tag values unknown at plan time")
        for finding in unknowns:
            print(f"  - {finding['address']} ({finding['type']}): {finding['reason']}")

    if untagged:
        print("")
        print("Taggable resources missing tag values")
        for finding in untagged:
            print(f"  - {finding['address']} ({finding['type']}): {finding['reason']}")

    if unsupported:
        by_type = collections.Counter(finding["type"] for finding in unsupported)
        print("")
        print("Resource types without tag fields")
        for resource_type, count in sorted(by_type.items()):
            print(f"  - {resource_type}: {count}")

        if verbose_unsupported:
            print("")
            print("Resources without tag fields")
            for finding in unsupported:
                print(f"  - {finding['address']} ({finding['type']})")

    if fail_on_missing_tags and untagged:
        return 1

    return 0


def main():
    parser = argparse.ArgumentParser(description="Report AWS Terraform resources with missing or unsupported tag coverage.")
    parser.add_argument("--input", required=True, help="Path to terraform show -json output, or - for stdin.")
    parser.add_argument("--source", default="terraform-json", help="Short label for the scanned document.")
    parser.add_argument(
        "--fail-on-missing-tags",
        action="store_true",
        help="Exit nonzero only when taggable resources are missing tag values.",
    )
    parser.add_argument(
        "--verbose-unsupported",
        action="store_true",
        help="Print every unsupported resource instead of only grouped type counts.",
    )
    args = parser.parse_args()

    document = load_document(args.input)
    if "resource_changes" in document:
        findings = collect_plan_findings(document)
    else:
        findings = collect_state_findings(document)

    return print_report(
        findings,
        args.source,
        fail_on_missing_tags=args.fail_on_missing_tags,
        verbose_unsupported=args.verbose_unsupported,
    )


if __name__ == "__main__":
    raise SystemExit(main())
