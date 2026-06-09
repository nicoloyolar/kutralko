# kutral_ko

A new Flutter project.

## Despliegue web

El panel puede publicarse con Firebase Hosting usando el proyecto Firebase ya configurado (`kutralko-2e192`).

1. Generar la version web:

   ```sh
   flutter build web --release
   ```

2. Revisar localmente antes de publicar:

   ```sh
   firebase emulators:start --only hosting
   ```

3. Publicar en Firebase Hosting:

   ```sh
   firebase deploy --only hosting
   ```

Al finalizar, Firebase entrega una URL publica para compartir con el cliente.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
