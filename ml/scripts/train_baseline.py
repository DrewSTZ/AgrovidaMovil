"""Entrena y evalúa el baseline YOLOv8 de clasificación."""

from __future__ import annotations

import argparse
import json
import os
import random
import shutil
from pathlib import Path

import numpy as np
import torch

CONFIG_DIR = Path(__file__).resolve().parents[1] / ".ultralytics"
CONFIG_DIR.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("YOLO_CONFIG_DIR", str(CONFIG_DIR))

from ultralytics import YOLO


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", type=Path, required=True)
    parser.add_argument("--project", type=Path, default=Path("ml/runs"))
    parser.add_argument("--name", default="banana_yolov8n_cls_v1")
    parser.add_argument("--model", default="yolov8n-cls.pt")
    parser.add_argument("--epochs", type=int, default=50)
    parser.add_argument("--batch", type=int, default=16)
    parser.add_argument("--imgsz", type=int, default=224)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--device", default="auto")
    return parser.parse_args()


def set_seeds(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def scalar(value: object) -> float | None:
    if value is None:
        return None
    if hasattr(value, "item"):
        return float(value.item())
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def main() -> None:
    args = parse_args()
    dataset = args.dataset.resolve()
    for split in ("train", "val", "test"):
        if not (dataset / split).is_dir():
            raise SystemExit(f"Falta el subconjunto {dataset / split}")

    set_seeds(args.seed)
    device: int | str = 0 if args.device == "auto" and torch.cuda.is_available() else args.device
    if args.device == "auto" and not torch.cuda.is_available():
        device = "cpu"

    project = args.project.resolve()
    model = YOLO(args.model)
    model.train(
        data=str(dataset),
        epochs=args.epochs,
        imgsz=args.imgsz,
        batch=args.batch,
        workers=0,
        seed=args.seed,
        deterministic=True,
        device=device,
        project=str(project),
        name=args.name,
        exist_ok=True,
        plots=True,
    )

    run_dir = project / args.name
    best_model_path = run_dir / "weights" / "best.pt"
    if not best_model_path.exists():
        raise SystemExit(f"No se generó el modelo esperado: {best_model_path}")

    best_model = YOLO(str(best_model_path))
    metrics = best_model.val(
        data=str(dataset),
        split="test",
        imgsz=args.imgsz,
        batch=args.batch,
        workers=0,
        device=device,
        project=str(run_dir),
        name="test",
        plots=True,
    )

    models_dir = Path("ml/models").resolve()
    models_dir.mkdir(parents=True, exist_ok=True)
    final_model = models_dir / "agrovida_banano_yolov8n_cls_v1.pt"
    shutil.copy2(best_model_path, final_model)

    summary = {
        "model": args.model,
        "dataset": str(dataset),
        "classes": [best_model.names[index] for index in sorted(best_model.names)],
        "epochs": args.epochs,
        "batch": args.batch,
        "imgsz": args.imgsz,
        "seed": args.seed,
        "device": str(device),
        "torch": torch.__version__,
        "cuda_available": torch.cuda.is_available(),
        "cuda_device": torch.cuda.get_device_name(0) if torch.cuda.is_available() else None,
        "test_top1": scalar(getattr(metrics, "top1", None)),
        "test_top5": scalar(getattr(metrics, "top5", None)),
        "best_model": str(final_model),
        "warning": "Resultado preliminar; no sustituye diagnostico profesional o de laboratorio.",
    }
    (run_dir / "baseline_summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
