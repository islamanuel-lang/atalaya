# Puesta en marcha

## Lo que hay que cambiar antes de compilar

| Sitio | Valor de ejemplo | Cámbialo por |
|---|---|---|
| `ios/project.yml` | `PRODUCT_BUNDLE_IDENTIFIER: es.atalaya.app` | Tu bundle ID |
| `ios/Atalaya/Resources/Atalaya.entitlements` | `group.es.atalaya.app` | Un App Group tuyo |
| Ajustes de la app | `https://api.atalaya.es` | Tu API |
| `web/.env` | `__TESTFLIGHT__`, `__APK__` | Tus enlaces reales |
| `android/app/build.gradle.kts` | `es.atalaya.app` | Tu applicationId |

La app lee el App Group de los entitlements en tiempo de ejecución, así que da
igual el nombre: solo tiene que existir y estar autorizado en el perfil.

## Backend

```bash
cd backend
cp .env.example .env
# edita ADMIN_KEY, TELEGRAM_*, ORIGINS y PUBLIC_BASE
npm install
npm test
npm run dev
```

- Datos en `backend/data/` (JSONL + ficheros). Nada de base de datos.
- Filtraciones: `data/leaks.txt`, un SHA-256 por línea de la frase normalizada.
- Admin: `/v1/admin/summary?key=...`, `/v1/admin/latest?kind=audits`,
  `/v1/admin/file/<nombre>`.
- Producción: un VPS con systemd o `pm2`, detrás de Caddy/Nginx con TLS.

## Web

```bash
cd web
cp .env.example .env
npm install
npm run build
npm run serve
```

El build inyecta API, TestFlight y APK en el HTML y en `app.js`. Publica el
resultado en Cloudflare Pages o GitHub Pages (workflow `web.yml`).

## iOS

### Opción A: Mac

```bash
brew install xcodegen
cd ios
xcodegen generate
open Atalaya.xcodeproj
```

En Xcode: equipo en *Signing & Capabilities*, App Group activo, dispositivo
físico, Run. Para distribuir, `Product → Archive`.

### Opción B: GitHub Actions (sin Mac)

`ios.yml` compila un IPA ad-hoc como artefacto. Para TestFlight hay un job
manual que necesita estos secretos:

- `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD` (certificado de distribución)
- `PROVISIONING_PROFILE_BASE64` (perfil con el App Group)
- `APPSTORE_KEY_ID`, `APPSTORE_ISSUER_ID`, `APPSTORE_KEY` (API key)

### Instalación en dispositivo

1. Instala iTunes de Apple (solo drivers) y [Impactor](https://github.com/claration/impactor/releases).
2. Conecta el iPhone por USB y confía en el equipo.
3. Impactor → cuenta Apple → instala el IPA. Impactor crea el App Group y le
   añade tu Team ID; la app lo resuelve sola.
4. Ajustes → General → VPN y Gestión de dispositivos → confiar en el certificado.

Sideloadly no conserva el App Group. Feather/ESign solo valen con un perfil que
incluya uno (los wildcard no).

### Verificación

- Ajustes dentro de la app: el App Group debe aparecer.
- Log: `handle: <positivo>` al consumir un contenedor.
- `-1` = sin App Group; `-2` = iOS sin las funciones; `-5` = consulta rechazada;
  `-6` = kernel; `-255` = ruta inexistente.

## Android

```bash
cd android
gradle assembleDebug        # o ./gradlew si generas wrapper
```

Instala el APK, concede acceso a fotos cuando lo pida y configura la API en la
última tarjeta de la pantalla. El MVP Android no tiene OCR ni escape: hace la
comprobación en línea y sube capturas del carrete.

## TestFlight

1. Cuenta de desarrollador de pago y app creada en App Store Connect.
2. Sube la build (job manual de `ios.yml`).
3. Grupo externo con enlace público; la primera build pasa revisión.
4. Reenvía versión antes de 90 días.
