# Estado del proyecto (handoff)

Fecha: 2026-11-24. Marca y dominio decididos: **SemenCheck** / `semencheck.es`.
El renombrado del repo está hecho; faltan los paneles.

## Infraestructura viva (aún con nombres viejos)

- Web: https://atalaya-app-3ck.pages.dev (proyecto Pages `atalaya-app`, hay que
  crear `semencheck` y desplegar ahí)
- API: https://atalaya-keie.onrender.com (Render free, servicio `atalaya-api`;
  renombrar a `semencheck-api`)
- Health: `https://atalaya-keie.onrender.com/v1/health` → `{"ok":true}`
- Repo: github.com/islamanuel-lang/atalaya → renombrar a `semencheck`
- Sesión de wrangler: iniciada en este equipo (`npx wrangler whoami`)
- La API duerme a los ~15 min; el primer acceso tarda ~30 s.

## Credenciales

- `ADMIN_KEY` de Render: el valor de abajo da 401, hay que fijar uno nuevo en el
  dashboard y anotarlo aquí. Valor viejo: `ba65cad02eac1e47646f82fbe4b8e485b32ff6e5a2285bbe`
- `ADMIN_KEY` del Worker (`wrangler.toml`): `6c7b24d353cc785acb36f5e4ebeabf04c6434c9d63ba2c2e`
- `backend/.env` local: existe (no versionado); `TELEGRAM_*` vacíos
- `web/.env` local: existe (no versionado), `SITE_URL=https://semencheck.es`
- `worker/.wrangler` local y login OAuth: en el perfil de usuario
- Bot de Telegram: sin crear (`@semencheck_bot` está ocupado, elegir otro)

## Pendiente inmediato, en orden

1. Comprar `semencheck.es` y reservar `semencheck.app` (301 al `.es`). Buzones
   `hola@` y `security@`. El `.com` está parkeado en GoDaddy: negociar aparte.
2. Reservar `@semencheck` (canal), `@semencheckapp` (respaldo) y
   `@semencheck_support` (grupo).
3. Buscar «SemenCheck» en OEPM y EUIPO (clases 9, 42 y 10/44) antes de encargar
   icono o ficha.
4. Crear proyecto Pages `semencheck`, desplegar `dist` y apuntar el dominio.
5. Renombrar repo, servicio de Render y worker; fijar `ADMIN_KEY` nueva y
   `TELEGRAM_*` cuando exista el bot.
6. Probar en iPhone con wallet de prueba (validación, informe, compartir). El
   móvil personal está en 27.2.1 y sigue afectado: no actualizar a 27.3 beta 2.
7. Decidir cuenta Apple (99 €) para TestFlight.

## Cómo retomar

```powershell
cd C:\Users\pi\atalaya        # la carpeta local aún se llama así
git pull
cd backend; npm install; npm run dev      # API local si hace falta
cd ..\web; npm install; npm run pack      # reconstruye dist
```

- Revisar `docs/deploy-gratis.md`, `docs/telegram.md` y `docs/runbook.md`.
- Publicar web: `npx wrangler pages deploy dist --project-name semencheck --branch main`
- Logs de API: dashboard de Render → Logs.

## Cambios importantes que quedan

- Sustituir `https://testflight.apple.com/join/REEMPLAZA` en `web/.env` cuando exista build.
- Subir APK a `web/semencheck.apk` o cambiar `APK_URL`.
- `ORIGINS` en Render debe llevar `https://semencheck.es` y ya no `pages.dev`
  cuando el dominio funcione.
- La web usa de momento `API_BASE=https://atalaya-keie.onrender.com`; cambiar a
  `https://api.semencheck.es` el día del dominio.
- Base de filtraciones: `backend/data/leaks.txt` tiene **un solo hash**.

## Avisos

- Render free pierde `backend/data/` al reiniciar: no es archivo histórico.
- La web pública contiene solo datos de prueba hasta que empiece la campaña.
- La marca se escribe **SemenCheck**; dominio, correo y handles todo en
  minúsculas. Primera mención siempre con «comprueba restos de tu semilla».
