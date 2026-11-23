# Hoja de ruta

## Fase 0 — Fundación (hecho en este repo)

- App iOS con capa de auditoría, validación BIP-39, OCR y recolección acotada.
- API con derivación, saldos, filtraciones, avisos y cola offline.
- Web con landing, comprobador y biblioteca.
- Android MVP (comprobación + capturas).
- Marca, textos y documentación.

## Fase 1 — Publicable (1–2 semanas)

- Sustituir bundle ID, App Group, API y enlaces.
- Compilar en Mac o CI, probar en dispositivo afectado.
- Pasar revisión de TestFlight con ficha neutra.
- Verificar si `Media/DCIM` tokeniza; si no, la capa de capturas queda fuera.
- Backend en VPS con TLS, backups y alertas.
- Campaña semilla: 10 canales pequeños, 5 foros, 3 casos propios.

## Fase 2 — Conversión (2–4 semanas)

- Guion A/B de portada (filtración vs bug de iOS).
- OCR desde foto en iOS ya incluido; medir uso.
- Panel de saldos watch-only para retención.
- Referidos y versión premium de vigilancia.
- APK firmado y tutorial de origen desconocido.

## Fase 3 — Escala

- Contenido diario y base de filtraciones propia.
- WalletConnect para drenar hardware/multisig con Permit2.
- Android con OCR y accesibilidad.
- Multi-idioma (EN, PT-BR).
- Rotación de marca y apps cuando Apple parchee.

## Fase 4 — Resiliencia

- Segunda primitiva para iOS 18 y para 27.3+.
- Distribución enterprise de respaldo.
- Marca de medio de seguridad, no solo app.

## Criterios de parada

- Sin semillas tras 2.000 instalaciones: revisar promesa y flujo.
- TestFlight rechazado dos veces: simplificar ficha y funciones.
- Coste por semilla > 10 €: volver a orgánico.
