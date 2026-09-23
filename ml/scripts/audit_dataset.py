"""Audita conteos y posibles fugas entre subconjuntos del dataset preparado."""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", type=Path, required=True)
    return parser.parse_args()


def main() -> None:
    dataset = parse_args().dataset.resolve()
    manifest_path = dataset / "manifest.csv"
    if not manifest_path.exists():
        raise SystemExit(f"No existe {manifest_path}")

    with manifest_path.open(encoding="utf-8-sig", newline="") as manifest_file:
        rows = list(csv.DictReader(manifest_file))

    counts = Counter((row["split"], row["class"]) for row in rows)
    digests: dict[str, set[str]] = defaultdict(set)
    groups: dict[str, set[str]] = defaultdict(set)
    missing_files: list[str] = []
    for row in rows:
        digests[row["sha256"]].add(row["split"])
        groups[row["source_group"]].add(row["split"])
        if not (dataset / row["output"]).exists():
            missing_files.append(row["output"])

    digest_leaks = {key: value for key, value in digests.items() if len(value) > 1}
    group_leaks = {key: value for key, value in groups.items() if len(value) > 1}
    result = {
        "images": len(rows),
        "counts": {
            split: {
                class_name: counts[(split, class_name)]
                for class_name in ("saludable", "sigatoka", "cordana")
            }
            for split in ("train", "val", "test")
        },
        "missing_files": len(missing_files),
        "exact_digest_leaks": len(digest_leaks),
        "source_group_leaks": len(group_leaks),
        "passed": not missing_files and not digest_leaks and not group_leaks,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    if not result["passed"]:
        raise SystemExit("La auditoría del dataset falló.")


if __name__ == "__main__":
    main()
