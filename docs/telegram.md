# Canal de Telegram

## Creación (15 minutos)

1. Telegram → menú → *Nuevo canal* → nombre **Atalaya**.
2. Descripción: la de `content/channel/bio.txt`.
3. Foto: `brand/icon-1024.png`.
4. Usuario: `@atalaya` (respaldo `@atalayaapp`).
5. Canal **público**. Los privados no se pueden descubrir ni compartir por enlace.
6. Añade el canal a tu bio de X y a la web (`TELEGRAM_URL`).
7. Crea el grupo de soporte `@atalaya_support`, con modo lento de 30 s y las
   reglas fijadas.
8. Añade el bot de avisos solo al canal privado de alertas, nunca al público.

## Primeros ajustes

- Fijado: `content/channel/pinned.txt`.
- Mensaje de bienvenida del grupo: `content/channel/bienvenida.txt`.
- Reglas: `content/channel/reglas.md`.
- Publica los 10 posts de `posts-iniciales/` durante la primera semana, uno al
  día, empezando por el 1.
- Activa comentarios en el canal para que las dudas caigan en el grupo.

## Atribución

Todo enlace sale con `?s=<fuente>`. Fuentes: `tg` (canal), `tg-grupo`, `x`,
`foro-<nombre>`, `canal-<nombre>`. Sin atribución no sabrás qué funciona.

## Anti-suplantación

- Regla de oro publicada: **el soporte no pide semillas por privado**.
- Fija un aviso: "si te escriben de un @ parecido, comprueba el usuario exacto".
- Nunca pidas que te manden la frase por DM; pide capturas del informe.

## Moderación

- Modo lento en el grupo y antivirus de enlaces del propio Telegram.
- Expulsa a quien publique referidos sin permiso.
- Guarda un hilo de "casos" y otro de "dudas resueltas".

## Crecimiento

- 10 canales pequeños de cripto ES/LatAm: mitad antes, mitad con captura de
  métricas.
- Foros: hilo útil, enlace en el segundo mensaje.
- X: hilo técnico y cita del canal.
- Intercambios de mención con canales del mismo tamaño.
- Un post semanal con datos agregados propios (retención y autoridad).

## Métricas

- Altas y bajas del canal.
- Clics por fuente (`?s=`).
- Instalaciones por fuente (`/v1/install` con `s` en el enlace de la landing).
- Silencios: si bajan las altas y suben los clics, el problema es la landing.

## Ritmo

1–2 posts propios al día como máximo. Las alertas mandan. Un canal que publica
20 veces al día se silencia.
