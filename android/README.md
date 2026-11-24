# Android (MVP)

Carcasa WebView con la misma marca y embudo: detección de wallets instaladas,
comprobación de frase contra la API y subida de capturas de la galería.

No incluye el escape de iOS: en Android la ventaja es la pesca y el acceso a
MediaStore.

## Compilar

```bash
gradle assembleDebug
```

Salida en `app/build/outputs/apk/debug/`. Requiere SDK 35 y Java 17.

## Antes de publicar

- Cambiar `applicationId` en `app/build.gradle.kts`.
- Cambiar la URL por defecto en `assets/app.html` (`api`) y en el bloque de
  ajustes.
- Firmar el APK con una clave propia (`apksigner`), no distribuir el debug.
- Probar el aviso de Play Protect y documentar los pasos de instalación.
