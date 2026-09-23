"""Prepara el dataset v1 de clasificación de hojas de banano."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import random
import re
import shutil
import unicodedata
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageOps, UnidentifiedImageError


CLASS_ALIASES = {
    "saludable": {"sanas", "sana", "saludable", "saludables", "healthy"},
    "sigatoka": {"sigatoka"},
    "cordana": {"cordana"},
}
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".tif", ".tiff"}


@dataclass(frozen=True)
class ImageRecord:
    source: Path
    relative_source: str
    class_name: str
    sha256: str
    perceptual_hash: int
    width: int
    height: int
    capture_day: str


class UnionFind:
    def __init__(self, size: int) -> None:
        self.parent = list(range(size))

    def find(self, item: int) -> int:
        while self.parent[item] != item:
            self.parent[item] = self.parent[self.parent[item]]
            item = self.parent[item]
        return item

    def union(self, first: int, second: int) -> None:
        first_root = self.find(first)
        second_root = self.find(second)
        if first_root != second_root:
            self.parent[second_root] = first_root


def normalized(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = "".join(character for character in value if not unicodedata.combining(character))
    return value.strip().lower().replace("-", "_").replace(" ", "_")


def detect_class(path: Path) -> str | None:
    parts = {normalized(part) for part in path.parts}
    for class_name, aliases in CLASS_ALIASES.items():
        if parts.intersection(aliases):
            return class_name
    return None


def detect_capture_day(filename: str) -> str:
    epoch_match = re.match(r"^(\d{13})", filename)
    if epoch_match:
        timestamp = int(epoch_match.group(1)) / 1000
        return datetime.fromtimestamp(timestamp, tz=timezone.utc).date().isoformat()
    date_match = re.search(r"(20\d{6})", filename)
    if date_match:
        return datetime.strptime(date_match.group(1), "%Y%m%d").date().isoformat()
    return "sin_fecha"


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source_file:
        for block in iter(lambda: source_file.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def difference_hash(image: Image.Image, hash_size: int = 8) -> int:
    grayscale = ImageOps.grayscale(image).resize(
        (hash_size + 1, hash_size), Image.Resampling.LANCZOS
    )
    pixels = list(grayscale.get_flattened_data())
    result = 0
    for row in range(hash_size):
        offset = row * (hash_size + 1)
        for column in range(hash_size):
            result <<= 1
            result |= pixels[offset + column] > pixels[offset + column + 1]
    return result


def hamming_distance(first: int, second: int) -> int:
    return (first ^ second).bit_count()


def scan_images(source_root: Path) -> tuple[list[ImageRecord], list[dict[str, str]]]:
    records: list[ImageRecord] = []
    rejected: list[dict[str, str]] = []
    for path in sorted(source_root.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in IMAGE_EXTENSIONS:
            continue
        class_name = detect_class(path.relative_to(source_root))
        if class_name is None:
            rejected.append({"source": str(path.relative_to(source_root)), "reason": "clase_no_reconocida"})
            continue
        try:
            with Image.open(path) as opened:
                opened.load()
                oriented = ImageOps.exif_transpose(opened).convert("RGB")
                width, height = oriented.size
                perceptual_hash = difference_hash(oriented)
        except (OSError, ValueError, UnidentifiedImageError) as error:
            rejected.append({"source": str(path.relative_to(source_root)), "reason": f"imagen_invalida: {error}"})
            continue
        records.append(
            ImageRecord(
                source=path,
                relative_source=path.relative_to(source_root).as_posix(),
                class_name=class_name,
                sha256=file_sha256(path),
                perceptual_hash=perceptual_hash,
                width=width,
                height=height,
                capture_day=detect_capture_day(path.stem),
            )
        )
    return records, rejected


def remove_exact_duplicates(
    records: list[ImageRecord],
) -> tuple[list[ImageRecord], list[dict[str, str]]]:
    unique: list[ImageRecord] = []
    first_by_digest: dict[str, ImageRecord] = {}
    duplicates: list[dict[str, str]] = []
    for record in records:
        previous = first_by_digest.get(record.sha256)
        if previous is None:
            first_by_digest[record.sha256] = record
            unique.append(record)
            continue
        duplicates.append(
            {
                "source": record.relative_source,
                "duplicate_of": previous.relative_source,
                "sha256": record.sha256,
            }
        )
    return unique, duplicates


def similar_groups(records: list[ImageRecord], max_distance: int) -> dict[int, list[int]]:
    union_find = UnionFind(len(records))
    by_class: dict[str, list[int]] = defaultdict(list)
    for index, record in enumerate(records):
        by_class[record.class_name].append(index)

    for indexes in by_class.values():
        for position, first_index in enumerate(indexes):
            first_hash = records[first_index].perceptual_hash
            for second_index in indexes[position + 1 :]:
                if hamming_distance(first_hash, records[second_index].perceptual_hash) <= max_distance:
                    union_find.union(first_index, second_index)

    by_capture_day: dict[str, list[int]] = defaultdict(list)
    for index, record in enumerate(records):
        if record.capture_day != "sin_fecha":
            by_capture_day[record.capture_day].append(index)
    for indexes in by_capture_day.values():
        first_index = indexes[0]
        for second_index in indexes[1:]:
            union_find.union(first_index, second_index)

    groups: dict[int, list[int]] = defaultdict(list)
    for index in range(len(records)):
        groups[union_find.find(index)].append(index)
    return groups


def assign_splits(
    records: list[ImageRecord],
    groups: dict[int, list[int]],
    seed: int,
    train_ratio: float,
    val_ratio: float,
) -> dict[int, str]:
    randomizer = random.Random(seed)
    assignment: dict[int, str] = {}
    splits = ("train", "val", "test")
    ratios = {"train": train_ratio, "val": val_ratio}
    ratios["test"] = 1 - train_ratio - val_ratio
    totals = Counter(record.class_name for record in records)
    targets = {
        split: {
            class_name: totals[class_name] * ratios[split]
            for class_name in CLASS_ALIASES
        }
        for split in splits
    }
    counts = {split: Counter() for split in splits}
    group_counts = {
        group_id: Counter(records[index].class_name for index in indexes)
        for group_id, indexes in groups.items()
    }
    ordered_groups = list(groups.items())
    randomizer.shuffle(ordered_groups)
    ordered_groups.sort(key=lambda item: len(item[1]), reverse=True)

    def assignment_cost(candidate: str, group_id: int) -> float:
        cost = 0.0
        for split in splits:
            for class_name in CLASS_ALIASES:
                value = counts[split][class_name]
                if split == candidate:
                    value += group_counts[group_id][class_name]
                target = targets[split][class_name]
                cost += ((value - target) / max(target, 1.0)) ** 2
        return cost

    for group_id, _ in ordered_groups:
        split = min(splits, key=lambda name: assignment_cost(name, group_id))
        assignment[group_id] = split
        counts[split].update(group_counts[group_id])

    for class_name in CLASS_ALIASES:
        print(
            f"{class_name}: "
            + str({split: counts[split][class_name] for split in splits})
        )
    return assignment


def save_image(record: ImageRecord, destination: Path, max_side: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(record.source) as opened:
        image = ImageOps.exif_transpose(opened).convert("RGB")
        image.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)
        image.save(destination, "JPEG", quality=92, optimize=True)


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8-sig") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--train-ratio", type=float, default=0.70)
    parser.add_argument("--val-ratio", type=float, default=0.15)
    parser.add_argument("--near-duplicate-distance", type=int, default=4)
    parser.add_argument("--max-side", type=int, default=1024)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    source_root = args.source.resolve()
    output_root = args.output.resolve()
    if not source_root.exists():
        raise SystemExit(f"No existe la carpeta de origen: {source_root}")
    if output_root.exists():
        shutil.rmtree(output_root)
    output_root.mkdir(parents=True)

    records, rejected = scan_images(source_root)
    unique_records, duplicates = remove_exact_duplicates(records)
    class_counts = Counter(record.class_name for record in unique_records)
    missing_classes = set(CLASS_ALIASES) - set(class_counts)
    if missing_classes:
        raise SystemExit(f"Faltan clases en el origen: {sorted(missing_classes)}")

    groups = similar_groups(unique_records, args.near_duplicate_distance)
    assignment = assign_splits(
        unique_records,
        groups,
        args.seed,
        args.train_ratio,
        args.val_ratio,
    )
    group_by_index = {
        index: group_id for group_id, indexes in groups.items() for index in indexes
    }

    manifest: list[dict[str, object]] = []
    sequence_by_class: Counter[str] = Counter()
    for index, record in enumerate(unique_records):
        group_id = group_by_index[index]
        split = assignment[group_id]
        sequence_by_class[record.class_name] += 1
        filename = f"{record.class_name}_{sequence_by_class[record.class_name]:05d}.jpg"
        relative_output = Path(split) / record.class_name / filename
        save_image(record, output_root / relative_output, args.max_side)
        manifest.append(
            {
                "output": relative_output.as_posix(),
                "source": record.relative_source,
                "class": record.class_name,
                "split": split,
                "source_group": f"grupo_{group_id:05d}",
                "capture_day": record.capture_day,
                "sha256": record.sha256,
                "dhash": f"{record.perceptual_hash:016x}",
                "original_width": record.width,
                "original_height": record.height,
            }
        )

    write_csv(
        output_root / "manifest.csv",
        manifest,
        [
            "output",
            "source",
            "class",
            "split",
            "source_group",
            "capture_day",
            "sha256",
            "dhash",
            "original_width",
            "original_height",
        ],
    )
    write_csv(
        output_root / "duplicates.csv",
        duplicates,
        ["source", "duplicate_of", "sha256"],
    )
    write_csv(
        output_root / "rejected.csv",
        rejected,
        ["source", "reason"],
    )

    split_counts = Counter((row["split"], row["class"]) for row in manifest)
    summary = {
        "dataset": "AgroVida banana leaf classification v1",
        "source_doi": "10.17632/hzttvh774g.1",
        "license": "CC BY 4.0",
        "seed": args.seed,
        "near_duplicate_hamming_distance": args.near_duplicate_distance,
        "source_images_found": len(records),
        "unique_images": len(unique_records),
        "exact_duplicates_removed": len(duplicates),
        "rejected_images": len(rejected),
        "similarity_groups": len(groups),
        "counts": {
            split: {
                class_name: split_counts[(split, class_name)]
                for class_name in CLASS_ALIASES
            }
            for split in ("train", "val", "test")
        },
        "limitation": (
            "La separacion conserva cada fecha de captura en un solo subconjunto "
            "y agrupa duplicados visuales. La fuente no publica identificadores "
            "por finca o planta, por lo que no puede garantizar independencia "
            "geografica estricta."
        ),
    }
    (output_root / "dataset_summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
