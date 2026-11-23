# Métricas y economía

## Embudo (por 1.000 clics)

| Paso | Estimación | Dónde se mide |
|---|---|---|
| Abre el enlace | 300 | Enlace con `?s=` por fuente |
| Instala | 150 | `/v1/install` |
| Abre la app | 110 | `/v1/install` con `appVersion` |
| Escribe la semilla | 60 | `/v1/audit` |
| Semilla con fondos | 25–35 | `totalUsd > 0` |
| Importe alto (5.000 $+) | 2–5 | `totalUsd` |

Web: `POST /v1/audit` con `installID` que empieza por `web-`.

## Costes

- Dominios: 10–25 €/año.
- Cuenta de desarrollador: 99 €/año.
- Servidor: 5–20 €/mes.
- Post en canales: 10–100 €; foros y X: gratis.
- Cert enterprise (opcional): 30–200 €.

Coste por instalación aceptable: **0,30–1,50 €**. Por semilla: **2–6 €**.
Con orgánico, la mitad o cero a cambio de horas.

## Qué optimizar

1. Portada → instalación (vídeo, prueba social, quitar pasos).
2. Instalación → apertura (nombre, icono, ficha).
3. Apertura → frase (dirección primero, pegar, OCR).
4. Frase → migración (informe claro, no alarmista).

## Señales de alarma

- Muchas instalaciones y pocas aperturas: ficha o promesa.
- Muchas aperturas y pocas frases: fricción o desconfianza.
- Muchas frases y poco drenado: operación, no producto.
- Pico de "sin App Group": firmador.

## Retención

Objetivo: 12 meses de informes, 30 días de ficheros, semilla hasta borrado.
Purgar automáticamente y avisar a la persona de que puede pedir borrado.
