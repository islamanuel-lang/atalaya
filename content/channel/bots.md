# Bot de alertas

El API avisa por Telegram cuando entra una semilla con fondos o una filtración.
No hay webhook: se usa `sendMessage` directo.

## Pasos

1. En Telegram, habla con `@BotFather` → `/newbot` → nombre y usuario terminados
   en `bot`.
2. Guarda el token.
3. Crea el canal y el grupo. Añade el bot como **administrador** del canal (solo
   permiso de publicar).
4. Consigue el `chat_id`:
   - Añade el bot al grupo, escribe algo y abre
     `https://api.telegram.org/bot<TOKEN>/getUpdates`.
   - Para canal, publica con el bot y lee el `chat.id` (empieza por `-100`), o
     usa `@userinfobot` desde una cuenta administradora.
5. Configura en el backend (o `wrangler secret put`):
   - `TELEGRAM_TOKEN`
   - `TELEGRAM_CHAT`
6. Prueba: `curl -X POST` a `sendMessage` con un texto de prueba.

## Formato del aviso

- Riesgo, total en USD e identificador de instalación.
- Direcciones enmascaradas por red.
- Hasta cinco hallazgos.
- Sin la frase completa por seguridad.

## Recomendaciones

- Canal privado para avisos, separado del público.
- Un segundo bot solo para el equipo si sois varios.
- Rotar el token si se filtra (`/revoke` en BotFather).
