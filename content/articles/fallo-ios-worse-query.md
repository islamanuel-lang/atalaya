---
title: La vulnerabilidad de iOS que pone tus datos en riesgo
description: Qué es worse_query, qué versiones afecta, qué permite y cómo comprobar si tu wallet está expuesta.
date: 2026-11-23
slug: fallo-ios-worse-query
tag: Vulnerabilidades
---

# La vulnerabilidad de iOS que pone tus datos en riesgo

El 8 de noviembre de 2026 se publicó `worse_query`, una prueba de concepto que
rompe el aislamiento entre apps en iOS 26 y 27. No es un jailbreak ni necesita
kernel: abusa de una consulta al gestor de contenedores de Apple para obtener
permiso de lectura sobre la carpeta de otra app.

Traducido: una app cualquiera puede leer los archivos que MetaMask, tu banco o
tu gestor de contraseñas dejan en su carpeta. No puede firmar transacciones ni
leer el Keychain, pero sí ver documentos, bases de datos, cachés y capturas.

## Qué alcanza

- Contenedores de datos de cualquier app.
- Contenedores de extensiones y daemons.
- Grupos de apps compartidos (los que usan widgets y extensiones).
- En iOS 27, también datos de sistema y grupos del sistema.

## Qué versiones

| Versión | Estado |
|---|---|
| iOS 26.0 – 26.7.2 | Afectado y probado |
| iOS 27.0 – 27.2.1 | Afectado (reportado) |
| iOS 27.3 beta 1 | Afectado |
| iOS 27.3 beta 2 y posteriores | **Parcheado** |

Apple publicó 26.7.3 y 27.2.1 el 9 de noviembre, pero no cerraron esta puerta:
la propia manutención de la técnica confirmó que seguía activa. El cierre llegó
en la beta 2 de 27.3.

## Por qué importa para cripto

Porque mucha gente guarda la frase semilla fuera de la wallet: una captura en el
galería, un `.txt` en Archivos, una nota copiada. Ahí no hay Keychain que valga:
son ficheros planos que el escape sí lee.

Las wallets que guardan la semilla en el llavero del sistema (la mayoría) no
quedan al descubierto por sí solas. Por eso SemenCheck combina comprobación de
filtraciones con revisión de restos en el móvil.

## Cómo comprobar si estás expuesto

1. Mira tu versión en Ajustes → General → Información. Si es 27.3 beta 2 o
   superior, el escape ya no actúa en tu móvil (la auditoría en línea sigue).
2. Revisa si tienes capturas con 12 o 24 palabras y bórralas tras migrar.
3. Pasa una auditoría: la app te dice qué wallets hay, qué ficheros con semilla
   encuentra y si la frase aparece en filtraciones conocidas.

## Qué hacer

Si el informe sale en riesgo alto: crea una wallet nueva, pasa los fondos, deja
de usar la frase antigua y borra sus copias. Una frase expuesta se considera
quemada para siempre.
