# Tomato Leaf Scanner

On-device tomato leaf disease detection for Flutter, powered by a YOLOv8 model
exported to TensorFlow Lite (INT8 quantized). Everything runs locally — no
network calls, no accounts.

> **Full documentation:** see [`docs/DOCUMENTATION.md`](docs/DOCUMENTATION.md) for
> architecture, the data/storage model, the scan pipeline, setup, and a
> presentation guide.

## Features

- **Live scan** — take a photo or pick one from the gallery and classify it on
  device with a YOLOv8 TFLite model.
- **15 classes** — aphids, early/late blight, leaf curl, leafhoppers/jassids,
  moulds, mosaic virus, Septoria, bacterial canker/spot, flea beetle, leafminer,
  powdery mildew, yellow curl virus, and healthy leaves.
- **Guidance** — each result shows cause, effects, immediate actions, prevention,
  and organic/chemical/cultural treatments.
- **Offline assistant** — rule-based Q&A that answers using the current
  diagnosis (spread, sprays, organic options, fruit safety, prevention).

## Project layout

```
lib/
  main.dart                 UI: Home / Scan / Result / Assistant pages
  models/detector.dart      TFLite loader + YOLOv8 decode (quantization aware)
  models/disease_info.dart  Disease knowledge base
  services/chat.dart        Offline rule-based assistant
assets/
  models/best_int8.tflite   YOLOv8 TFLite model
  samples/                  Optional sample leaf images (sample1.jpg, ...)
```

## Requirements

- Flutter 3.3+ (Dart SDK `>=3.3.0 <4.0.0`)

## Run

```bash
flutter pub get
flutter run
```

To run on a physical device, camera access is required. iOS usage descriptions
and Android permissions are already configured.

## Tests

```bash
flutter test
flutter analyze
```

## Model notes

The bundled model is a YOLOv8 detection export with an INT8 input tensor. The
loader reads the input/output tensor types and quantization parameters at
runtime, so it also works with a float32 export of the same graph. Output is
expected as `[1, 4 + numClasses, numAnchors]` (channel-first); the code also
accepts the transposed `[1, numAnchors, 4 + numClasses]` layout.

## Adding sample leaves

Drop `sample1.jpg`, `sample2.jpg`, `sample3.jpg` into `assets/samples/`. The
sample row appears automatically once the files exist; when the folder is empty
the row is hidden.

## Disclaimer

Tomato Leaf Scanner gives an AI estimate from a single photo, not a lab test. Confirm
serious outbreaks with your local extension officer.
