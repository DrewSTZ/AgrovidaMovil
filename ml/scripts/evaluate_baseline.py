"""Evalúa el modelo de clasificación y documenta sus errores por clase."""

from __future__ import annotations

import argparse
import csv
import json
import os
from collections import Counter
from pathlib import Path

CONFIG_DIR = Path(__file__).resolve().parents[1] / ".ultralytics"
CONFIG_DIR.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("YOLO_CONFIG_DIR", str(CONFIG_DIR))

from ultralytics import YOLO


IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=Path, required=True)
    parser.add_argument("--dataset", type=Path, required=True)
    parser.add_argument("--split", default="test")
    parser.add_argument("--output", type=Path, default=Path("ml/reports/baseline_v1"))
    parser.add_argument("--imgsz", type=int, default=224)
    parser.add_argument("--batch", type=int, default=64)
    parser.add_argument("--device", default="0")
    parser.add_argument("--low-confidence", type=float, default=0.70)
    return parser.parse_args()


def safe_divide(numerator: int, denominator: int) -> float:
    return numerator / denominator if denominator else 0.0


def display_path(path: Path, project_root: Path) -> str:
    try:
        return path.resolve().relative_to(project_root).as_posix()
    except ValueError:
        return str(path.resolve())


def main() -> None:
    args = parse_args()
    project_root = Path(__file__).resolve().parents[2]
    split_dir = args.dataset.resolve() / args.split
    if not split_dir.is_dir():
        raise SystemExit(f"No existe el subconjunto: {split_dir}")
    if not args.model.is_file():
        raise SystemExit(f"No existe el modelo: {args.model}")
    if not 0.0 <= args.low_confidence <= 1.0:
        raise SystemExit("--low-confidence debe estar entre 0 y 1")

    image_paths = sorted(
        path
        for path in split_dir.rglob("*")
        if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES
    )
    if not image_paths:
        raise SystemExit(f"No hay imágenes en {split_dir}")

    model = YOLO(str(args.model.resolve()))
    classes = [model.names[index] for index in sorted(model.names)]
    dataset_classes = sorted(path.name for path in split_dir.iterdir() if path.is_dir())
    if sorted(classes) != dataset_classes:
        raise SystemExit(
            "Las clases del modelo y del dataset no coinciden: "
            f"modelo={classes}, dataset={dataset_classes}"
        )

    predictions = model.predict(
        source=[str(path) for path in image_paths],
        imgsz=args.imgsz,
        batch=args.batch,
        device=args.device,
        verbose=False,
    )
    if len(predictions) != len(image_paths):
        raise SystemExit("La cantidad de predicciones no coincide con las imágenes")

    confusion = {actual: Counter({predicted: 0 for predicted in classes}) for actual in classes}
    rows: list[dict[str, object]] = []
    low_confidence_count = 0

    for image_path, result in zip(image_paths, predictions, strict=True):
        if result.probs is None:
            raise SystemExit(f"El modelo no devolvió probabilidades para {image_path}")
        actual = image_path.parent.name
        predicted = model.names[int(result.probs.top1)]
        confidence = float(result.probs.top1conf.item())
        probabilities = [float(value) for value in result.probs.data.tolist()]
        is_low_confidence = confidence < args.low_confidence
        low_confidence_count += int(is_low_confidence)
        confusion[actual][predicted] += 1

        row: dict[str, object] = {
            "image": image_path.relative_to(split_dir).as_posix(),
            "actual": actual,
            "predicted": predicted,
            "confidence": round(confidence, 8),
            "correct": actual == predicted,
            "below_candidate_threshold": is_low_confidence,
        }
        for index, class_name in enumerate(classes):
            row[f"probability_{class_name}"] = round(probabilities[index], 8)
        rows.append(row)

    total = len(rows)
    correct = sum(int(row["correct"]) for row in rows)
    per_class: dict[str, dict[str, object]] = {}
    for class_name in classes:
        class_total = sum(confusion[class_name].values())
        class_correct = confusion[class_name][class_name]
        false_positives = sum(
            confusion[other][class_name] for other in classes if other != class_name
        )
        false_negatives = class_total - class_correct
        precision = safe_divide(class_correct, class_correct + false_positives)
        recall = safe_divide(class_correct, class_correct + false_negatives)
        f1 = safe_divide(2 * precision * recall, precision + recall)
        per_class[class_name] = {
            "total": class_total,
            "correct": class_correct,
            "errors": false_negatives,
            "accuracy_recall": round(recall, 8),
            "precision": round(precision, 8),
            "f1": round(f1, 8),
            "confused_as": {
                predicted: count
                for predicted, count in confusion[class_name].items()
                if predicted != class_name and count
            },
        }

    report = {
        "model": display_path(args.model, project_root),
        "dataset": display_path(args.dataset, project_root),
        "split": args.split,
        "classes": classes,
        "total": total,
        "correct": correct,
        "errors": total - correct,
        "accuracy": round(safe_divide(correct, total), 8),
        "macro_f1": round(
            sum(float(values["f1"]) for values in per_class.values()) / len(classes), 8
        ),
        "candidate_low_confidence_threshold": args.low_confidence,
        "below_candidate_threshold": low_confidence_count,
        "per_class": per_class,
        "confusion_matrix": {
            actual: {predicted: confusion[actual][predicted] for predicted in classes}
            for actual in classes
        },
        "warning": (
            "Baseline de investigación. El umbral de confianza es candidato y debe "
            "calibrarse antes de integrarlo. No sustituye un diagnóstico profesional."
        ),
    }

    output_dir = args.output.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "test_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    fieldnames = list(rows[0])
    with (output_dir / "test_predictions.csv").open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
