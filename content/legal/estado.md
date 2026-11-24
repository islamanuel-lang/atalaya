---
title: Estado de la técnica por versión de iOS
description: Qué versiones están afectadas por el escape de sandbox, cuáles están parcheadas y qué se puede hacer en cada una.
slug: estado
kind: page
updated: 2026-11-24
---

# Estado por versión de iOS

Actualizado el 24 de noviembre de 2026. Esta página se revisa con cada versión.

| Versión | Lectura de contenedores | Auditoría en línea | Nota |
|---|---|---|---|
| iOS 18.x | No (usa otra técnica) | Sí | Fuera de alcance de SemenCheck iOS |
| iOS 26.0 – 26.7.2 | Sí | Sí | Sin datos de sistema |
| iOS 27.0 – 27.2.1 | Sí | Sí | Sistema y grupos incluidos |
| iOS 27.3 beta 1 | Sí | Sí | Última beta vulnerable |
| iOS 27.3 beta 2+ | **No** | Sí | Parcheado por Apple |

## Qué cambia al actualizar

En versiones parcheadas, `worse_query` ya no consigue permiso de lectura:
SemenCheck no puede abrir carpetas de otras apps ni revisar restos. Se mantiene
la comprobación en línea (filtraciones, direcciones y saldos) y la detección de
wallets instaladas, que no depende del escape.

## Cómo saber tu versión

Ajustes → General → Información → Versión de iOS.

## Criterio

Si estás en 26.0–27.2.1, no hay prisa por actualizar por este fallo en concreto;
valora el resto de parches de seguridad. Si estás en 27.3 beta 2 o superior, ya
estás protegido y la app funciona en modo auditoría.

Fuente primaria: `github.com/forcequitOS/worse_query` y notas de Apple del 9 de
noviembre de 2026.
