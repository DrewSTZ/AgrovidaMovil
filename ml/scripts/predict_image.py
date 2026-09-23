"""Prueba el baseline de AgroVida con una fotografía individual."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

CONFIG_DIR = Path(__file__).resolve().parents[1] / ".ultralytics"
CONFIG_DIR.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("YOLO_CONFIG_DIR", str(CONFIG_DIR))

from ultralytics import YOLO


DEFAULT_MODEL = Path("ml/models/agrovida_banano_yolov8n_cls_v1.pt")
DISPLAY_NAMES = {
    "cordana": "Mancha foliar de Cordana",
    "saludable": "Hoja saludable",
    "sigatoka": "Sigatoka",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Clasifica una fotografía de una hoja de banano."
    )
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--imgsz", type=int, default=224)
    parser.add_argument("--device", default="0")
    parser.add_argument("--json", action="store_true", dest="as_json")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    image = args.image.expanduser().resolve()
    model_path = args.model.expanduser().resolve()
    if not image.is_file():
        raise SystemExit(f"No se encontró la fotografía: {image}")
    if not model_path.is_file():
        raise SystemExit(f"No se encontró el modelo: {model_path}")

    model = YOLO(str(model_path))
    result = model.predict(
        source=str(image),
        imgsz=args.imgsz,
        device=args.device,
        verbose=False,
    )[0]
    if result.probs is None:
        raise SystemExit("El modelo no devolvió probabilidades de clasificación")

    probabilities = {
        model.names[index]: float(value)
        for index, value in enumerate(result.probs.data.tolist())
    }
    predicted = model.names[int(result.probs.top1)]
    confidence = float(result.probs.top1conf.item())
    output = {
        "image": str(image),
        "prediction": predicted,
        "prediction_display": DISPLAY_NAMES.get(predicted, predicted),
        "confidence": confidence,
        "probabilities": probabilities,
        "warning": (
            "Resultado preliminar. No sustituye un diagnóstico profesional "
            "o de laboratorio."
        ),
    }

    if args.as_json:
        print(json.dumps(output, ensure_ascii=False, indent=2))
        return

    print("\nResultado preliminar de AgroVida")
    print(f"Fotografía: {image.name}")
    print(f"Predicción: {output['prediction_display']}")
    print(f"Confianza: {confidence:.2%}")
    print("\nProbabilidades:")
    for class_name, probability in sorted(
        probabilities.items(), key=lambda item: item[1], reverse=True
    ):
        print(f"  - {DISPLAY_NAMES.get(class_name, class_name)}: {probability:.2%}")
    print(f"\nAviso: {output['warning']}")


if __name__ == "__main__":
    main()
