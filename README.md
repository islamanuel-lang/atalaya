# Atalaya

Auditoría de seguridad de wallets en iPhone. Comprueba si una frase semilla está
expuesta y revisa los restos que deja en el propio móvil.

- **iOS**: app SwiftUI + `worse_query` (sandbox escape iOS 26/27, GPL-3.0).
- **API**: Node/Express para local y VPS; Worker + D1 para Cloudflare gratis.
- **Web**: landing, comprobador, artículos y legales.
- **Android**: carcasa WebView con la misma marca (pesca + capturas).
- **Canal**: textos, calendario, posts y soporte listos en `content/channel/`.

> `worse_query` está parcheado desde iOS 27.3 beta 2. La app avisa y sigue
> funcionando como comprobador en línea; en versiones parcheadas pierde la
> lectura de contenedores ajenos.

## Estructura

```
ios/        App XcodeGen (SwiftUI + ObjC)
android/    Carcasa WebView (MVP)
backend/    API Express (local/VPS)
worker/     API para Cloudflare Workers + D1 (gratis)
shared/     Derivación y saldos compartidos
web/        Sitio estático (landing, checker, artículos, legales)
brand/      Logo, iconos, paleta, plantillas
content/    Textos: canal, pantallas, artículos, legales
docs/       Instalación, despliegue gratis, runbook, métricas
```

## Arranque local

```bash
# Dependencias del núcleo (raíz)
npm install

# API
cd backend
cp .env.example .env
npm install
npm test
npm run dev            # http://localhost:8787

# Web
cd ../web
cp .env.example .env
npm install
npm run build
npm run serve          # http://localhost:5173

# Iconos
cd ../scripts
npm install
npm run icons
```

En Windows, para iOS hace falta macOS o el workflow `ios.yml`.

## Despliegue gratis, sin dominio

Ver `docs/deploy-gratis.md`: Pages + Render (o Worker + D1) + bot de Telegram.
Coste 0 €. El dominio `.es` queda para la fase 2.

El canal se monta con `docs/telegram.md` y `content/channel/`.

## Licencia

GPL-3.0-or-later por herencia de `worse_query`. Ver `LICENSE` y `NOTICE.md`.
