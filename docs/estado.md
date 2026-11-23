# Estado del proyecto (handoff)

Fecha: 2026-11-24. Para retomar mañana.

## Infraestructura viva

- Web: https://atalaya-app-3ck.pages.dev (Cloudflare Pages, proyecto `atalaya-app`)
- API: https://atalaya-keie.onrender.com (Render free, servicio `atalaya-api`)
- Health: `https://atalaya-keie.onrender.com/v1/health` → `{"ok":true}`
- Repo: github.com/islamanuel-lang/atalaya (privado → luego público para Render)
- Sesión de wrangler: iniciada en este equipo (`npx wrangler whoami`)
- La API duerme a los ~15 min; el primer acceso tarda ~30 s.

## Credenciales

- `ADMIN_KEY` de Render: `ba65cad02eac1e47646f82fbe4b8e485b32ff6e5a2285bbe`
  (rotar cuando se comparta el panel)
- `backend/.env` local: existe (no versionado)
- `web/.env` local: existe con API y dominio reales (no versionado)
- `worker/.wrangler` local y login OAuth: en el perfil de usuario
- Telegram: pendiente de crear bot

## Verificado hoy

- Auditoría real desde la web publicada: riesgo alto, dirección y saldo reales.
- CORS de `atalaya-app-3ck.pages.dev` autorizado.
- Cabeceras de seguridad activas (`_headers`).
- Worker + D1 probados en local, no desplegados.

## Pendiente inmediato

1. Probar en iPhone con wallet de prueba (validación, informe, compartir).
2. Crear canal `@atalaya` y grupo `@atalaya_support`; foto, bio, reglas, fijado.
3. Publicar posts 1–3 de `content/channel/posts-iniciales/`.
4. Crear bot en `@BotFather`, añadirlo a un canal privado de alertas, poner
   `TELEGRAM_TOKEN` y `TELEGRAM_CHAT` en Render y probar.
5. Decidir cuenta Apple (99 €) para TestFlight.

## Cómo retomar

```powershell
cd C:\Users\pi\atalaya
git pull
cd backend; npm install; npm run dev      # API local si hace falta
cd ..\web; npm install; npm run pack      # reconstruye dist
```

- Revisar `docs/deploy-gratis.md`, `docs/telegram.md` y `docs/runbook.md`.
- Publicar cambios de web: `npx wrangler pages deploy dist --project-name atalaya-app --branch main`
- Logs de API: dashboard de Render → Logs.

## Cambios importantes que quedan

- Sustituir `https://testflight.apple.com/join/REEMPLAZA` en `web/.env` cuando exista build.
- Subir APK a `web/atalaya.apk` o cambiar `APK_URL`.
- `ORIGINS` en Render debe mantener el dominio de Pages y el de dominio propio el día que se compre.
- El dominio `atalaya.es` sigue pendiente (fase 2).

## Avisos

- Render free pierde `backend/data/` al reiniciar: no es archivo histórico.
- La web pública contiene solo datos de prueba hasta que empiece la campaña.
- El repo se hará privado de nuevo y se desplegará con wrangler CLI (ya iniciado).
