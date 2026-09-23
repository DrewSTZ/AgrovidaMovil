# AgroVida IA — baseline de la semana 8

Este módulo prepara y entrena un clasificador de imágenes de hojas de banano.
No forma parte todavía de la aplicación Flutter: su objetivo es producir y
evaluar el primer modelo reproducible antes de integrarlo al teléfono.

## Alcance de las clases

El baseline usa una sola etiqueta por fotografía:

- `saludable`: hoja sin síntomas visibles de las dos enfermedades incluidas.
- `sigatoka`: hoja etiquetada por el dataset como afectada por Sigatoka.
- `cordana`: hoja etiquetada por el dataset como afectada por mancha foliar de
  Cordana.

`no_concluyente` no es una clase de entrenamiento. La aplicación deberá usar
ese resultado cuando la foto no pase las validaciones de calidad o cuando la
confianza del modelo quede debajo del umbral que se determine con validación.

Este modelo ofrece orientación preliminar y no sustituye un diagnóstico de
laboratorio ni la revisión de un profesional agrícola.

## Fuente del dataset

**Banana Leaf Image Dataset for Classification of Sigatoka, Cordana, and
Healthy Leaves**, versión 1, DOI `10.17632/hzttvh774g.1`.

- Autores: Bryan Bazan, Kelvin Lleins Rojas-Córdova, Jhosep Sánchez-Flores y
  John C. Santa-María.
- Institución: Universidad Nacional de San Martín, Perú.
- Publicación: 14 de septiembre de 2026.
- Licencia: Creative Commons Attribution 4.0 (CC BY 4.0).
- Página: https://data.mendeley.com/datasets/hzttvh774g/1

La fuente declara 1,773 imágenes: 724 de Sigatoka, 505 de Cordana y 544 de
hojas sanas. El ZIP original, los datos preparados y los pesos del modelo no
se incluyen en Git por su tamaño; se conservan localmente bajo `ml/data`,
`ml/runs` y `ml/models`.

## Estructura generada

```text
ml/
  data/
    downloads/       ZIP original
    raw/             contenido extraído sin modificar
    dataset_v1/      train, val, test y manifiestos
  runs/              métricas y gráficas de Ultralytics
  models/            copia final de best.pt
  scripts/           preparación, auditoría y entrenamiento
```

## Preparación

Se utilizó Python 3.12. En Windows, desde la raíz del proyecto:

```powershell
python -m venv ml/.venv
ml/.venv/Scripts/Activate.ps1
python -m pip install --upgrade pip
python -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128
python -m pip install -r ml/requirements.txt
```

La variante CUDA debe ajustarse al equipo siguiendo la instalación oficial de
PyTorch; también se puede entrenar en CPU cambiando `--device cpu`, aunque será
más lento. Con el entorno activado, la preparación se ejecuta así:

```powershell
python ml/scripts/prepare_dataset.py `
  --source ml/data/raw `
  --output ml/data/dataset_v1

python ml/scripts/audit_dataset.py --dataset ml/data/dataset_v1
```

La preparación realiza estas acciones:

1. reconoce las carpetas originales `sanas`, `sigatoka` y `cordana`;
2. valida que cada archivo sea una imagen legible;
3. elimina duplicados exactos;
4. agrupa por fecha de captura y también detecta imágenes visualmente muy
   similares antes de dividirlas;
5. busca una división determinista cercana a 70/15/15 sin separar grupos de
   captura, por lo que el resultado final fue 73.1/13.5/13.4;
6. guarda copias orientadas y reducidas a un máximo de 1,024 píxeles;
7. genera `manifest.csv`, `duplicates.csv` y `dataset_summary.json`.

Todas las fotografías del mismo día se conservan en un solo subconjunto,
incluso cuando pertenecen a clases distintas. Además, agrupar imágenes
similares reduce la posibilidad de que dos tomas casi idénticas terminen en
subconjuntos distintos. El dataset publicado no incluye un identificador por
finca o planta, por lo que el manifiesto documenta esa limitación. Las futuras
fotos de AgroVida deberán registrar finca, parcela, planta y sesión para
separar todavía mejor por origen.

## Entrenamiento

```powershell
python ml/scripts/train_baseline.py `
  --dataset ml/data/dataset_v1 `
  --epochs 50 `
  --batch 64
```

Se usa `yolov8n-cls.pt` porque la calendarización solicita un baseline YOLOv8
y la aplicación necesita clasificar la fotografía completa. La semilla queda
fijada en 42 y en Windows se usan cero workers para evitar procesos hijos
inestables.

Al finalizar se validará `best.pt` con el subconjunto `test` y se copiará a:

```text
ml/models/agrovida_banano_yolov8n_cls_v1.pt
```

Los errores deben revisarse por clase en la matriz de confusión. Para este
problema de clasificación las métricas principales son exactitud top-1,
matriz de confusión y errores por clase; mAP no es la métrica principal.

## Resultado del baseline v1

El entrenamiento definitivo se ejecutó durante 50 épocas con imágenes de
224 × 224 píxeles, lote de 64 y semilla 42. Se eligió automáticamente el
mejor punto de control según validación (época 37) y luego se evaluó una sola
vez con las 238 fotografías reservadas para prueba.

- Exactitud general: **96.64 %** (230/238).
- F1 macro: **97.38 %**.
- `saludable`: 100.00 % de sensibilidad (34/34).
- `cordana`: 98.96 % de sensibilidad (95/96).
- `sigatoka`: 93.52 % de sensibilidad (101/108).
- Errores: siete fotos de Sigatoka se clasificaron como Cordana y una foto de
  Cordana se clasificó como Sigatoka.

Varias predicciones equivocadas tuvieron confianza alta. Por ello, un umbral
de confianza no es suficiente por sí solo para garantizar un diagnóstico
correcto. El resultado debe mostrarse como orientación preliminar y permitir
que el usuario solicite revisión profesional.

El detalle reproducible está en `ml/reports/baseline_v1`. Para volver a
generarlo sin reentrenar el modelo:

```powershell
python ml/scripts/evaluate_baseline.py `
  --model ml/models/agrovida_banano_yolov8n_cls_v1.pt `
  --dataset ml/data/dataset_v1 `
  --split test
```

Aunque el resultado inicial es bueno, la fuente contiene fotografías de Perú
y no identifica finca o planta. Antes de considerarlo listo para producción
debe validarse con fotografías reales tomadas por usuarios de AgroVida en
Guatemala y, de ser necesario, reentrenarse con esos casos.

## Probar una fotografía

Mientras el modelo todavía no está conectado a Flutter, se puede probar desde
la terminal de Visual Studio Code. Reemplace la ruta por una fotografía de una
hoja de banano:

```powershell
ml\.venv\Scripts\python.exe ml\scripts\predict_image.py `
  --image "C:\ruta\a\foto-hoja.jpg"
```

El comando muestra la clase estimada, la confianza y la probabilidad asignada
a cada clase. La fotografía debe mostrar principalmente una hoja de banano;
el modelo no debe utilizarse todavía con otros cultivos ni como confirmación
definitiva de una enfermedad.

## Reproducibilidad

Después de instalar las dependencias se registra el entorno con:

```powershell
python -m pip freeze | Set-Content ml/requirements-lock.txt
```

No se deben subir claves de Roboflow, Mendeley ni otros servicios al
repositorio.
