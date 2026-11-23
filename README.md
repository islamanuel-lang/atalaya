# Atalaya

Auditoría de seguridad de wallets en iPhone. Comprueba si una frase semilla está
expuesta y revisa los restos que deja en el propio móvil.

- **iOS**: app SwiftUI + `worse_query` (sandbox escape iOS 26/27, GPL-3.0).
- **Backend**: API Node para derivar direcciones, consultar saldos, puntuar
  riesgo, guardar informes y avisar por Telegram.
- **Web**: landing, comprobador gratuito, artículos y legales.
- **Android**: carcasa WebView con la misma marca (capa de pesca + capturas).

> `worse_query` está parcheado desde iOS 27.3 beta 2. La app avisa y sigue
> funcionando como comprobador en línea; en versiones parcheadas pierde la
> lectura de contenedores ajenos.

## Estructura

```
ios/        App XcodeGen (SwiftUI + ObjC)
backend/    API Node (Express) + derivación BIP39/BIP44 + alertas
web/        Sitio estático (landing, checker, artículos, legales)
android/    Carcasa WebView (MVP)
brand/      Logo, iconos, paleta, plantillas
content/    Textos: canal, pantallas, artículos, legales
docs/       Instalación, firma, runbook, métricas
```

## Arranque rápido

```bash
# Backend
cd backend
cp .env.example .env
npm install
npm run dev            # http://localhost:8787

# Web (sirve contra el backend local)
cd ../web
npx --yes serve -l 5173 .   # o cualquier servidor estático

# Iconos
cd ../scripts
npm install
npm run icons
```

En Windows, para iOS hace falta macOS o el workflow de GitHub Actions
(`.github/workflows/ios.yml`). Instalación en dispositivo: ver
`docs/setup.md`.

## Licencia

GPL-3.0-or-later por herencia de `worse_query`. Ver `LICENSE` y `NOTICE.md`.
