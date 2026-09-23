# Reporte del baseline v1

Evaluación del clasificador YOLOv8n de hojas de banano sobre el subconjunto
`test`, conservado fuera del entrenamiento y de la selección del modelo.

## Resultado

| Clase real | Correctas | Total | Sensibilidad |
|---|---:|---:|---:|
| Cordana | 95 | 96 | 98.96 % |
| Saludable | 34 | 34 | 100.00 % |
| Sigatoka | 101 | 108 | 93.52 % |
| **Total** | **230** | **238** | **96.64 %** |

La F1 macro fue 97.38 %. Los ocho errores se concentraron entre las dos
enfermedades: siete imágenes de Sigatoka se predijeron como Cordana y una de
Cordana como Sigatoka. Ninguna imagen enferma se clasificó como saludable y
ninguna saludable se clasificó como enferma en este conjunto de prueba.

El archivo `test_report.json` contiene las métricas y la matriz numérica.
`test_predictions.csv` conserva la predicción, confianza y probabilidades de
cada fotografía. `confusion_matrix.png` permite revisar visualmente las
confusiones. `dataset_summary.json` y `dataset_audit.json` documentan la
distribución de las 1,773 imágenes y confirman que no existen archivos ni
grupos de captura compartidos entre los subconjuntos.

## Interpretación responsable

Este es un baseline de investigación y no un diagnóstico agrícola definitivo.
La exactitud fue medida con fotografías de la misma fuente publicada, aunque
las fechas de captura se separaron entre entrenamiento, validación y prueba.
La fuente no aporta identificadores de finca o planta y todavía falta una
validación externa con imágenes capturadas por usuarios en Guatemala.

Un umbral candidato de 70 % marcó solo tres fotografías como de baja
confianza, pero los ocho errores tuvieron confianza superior a ese valor. Por
lo tanto, la confianza no puede utilizarse como única medida de seguridad.
