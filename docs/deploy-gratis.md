# Despliegue gratis, sin dominio

Arquitectura de coste cero:

- **Web**: Cloudflare Pages (`atalaya.pages.dev`), HTTPS y CDN gratis.
- **API**: Render free (`atalaya-api.onrender.com`) con el mismo servidor que
  usas en local.
- **Avisos**: bot de Telegram.

Sin tarjeta, sin dominio, sin Mac.

## 1. API en Render

1. Crea cuenta en render.com y conecta el repositorio.
2. *New → Blueprint* y elige `render.yaml` (ya incluido).
3. Rellena los secretos que pide (Telegram) y guarda el `ADMIN_KEY` generado.
4. Espera el despliegue y comprueba `https://<servicio>/v1/health`.
5. Si el plan free duerme por inactividad, el primer acceso tarda ~30 s.

Límites del plan free: se duerme tras 15 min, disco efímero (los JSONL se
pierden en cada reinicio). Para un MVP vale; cuando haya volumen, plan de 7 $ con
disco o migra a VPS.

## 2. Web en Pages

```bash
cd web
cp .env.example .env
# API_BASE=https://atalaya-api.onrender.com
# TELEGRAM_URL=https://t.me/atalaya
npm install
npm run build
npx wrangler pages deploy . --project-name=atalaya
```

Primera vez: `npx wrangler login` (navegador) o usa el workflow
`deploy-free.yml` con los secretos `CLOUDFLARE_API_TOKEN` y
`CLOUDFLARE_ACCOUNT_ID` y las variables `API_BASE`, `SITE_URL`, `TELEGRAM_URL`,
`TESTFLIGHT_URL`, `APK_URL`, `PAGES_PROJECT`.

Ajusta `web/_headers` y `worker/wrangler.toml` con el subdominio real.

## 3. Alternativa: API en Worker + D1

Gratis, sin hibernación. Requiere cuenta de Cloudflare y aceptar que el código
vive en un runtime distinto.

```bash
cd worker
npm install
npx wrangler login
npx wrangler d1 create atalaya          # copia el id a wrangler.toml
npm run sync
npx wrangler d1 execute atalaya --remote --file schema.sql
npx wrangler secret put ADMIN_KEY
npx wrangler secret put TELEGRAM_TOKEN
npx wrangler secret put TELEGRAM_CHAT
npm run deploy
```

Carga las filtraciones:

```bash
while read h; do echo "INSERT OR IGNORE INTO leaks (hash) VALUES ('$h');"; done < backend/data/leaks.txt > leaks.sql
npx wrangler d1 execute atalaya --remote --file leaks.sql
```

Nota: el runtime de `wrangler dev` en Windows de este equipo se reinicia tras la
primera petición. El código de derivación y saldos funciona dentro de workerd;
si te pasa, prueba `wrangler dev --remote` o usa Render.

## 4. Enlaces del canal

Publica el enlace con atribución: `https://atalaya.pages.dev/?s=tg&c=1`.
Cambia `s` por cada fuente (foro, canal, X) para saber qué convierte.

## 5. Coste real y siguiente paso

| Concepto | Coste |
|---|---|
| Pages | 0 € |
| Render free | 0 € |
| Worker + D1 (opcional) | 0 € |
| Dominio `.es` | ~12 €/año (fase 2) |

Cuando haya 100 instalaciones: compra `atalaya.es`, apunta Pages y la API a ese
dominio, 301 desde `pages.dev` y actualiza `ORIGINS` y `_headers`.
