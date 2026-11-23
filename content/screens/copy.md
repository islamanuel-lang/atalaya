# Guion de las 7 pantallas

Texto listo para implementar. Entre corchetes, elementos de UI.

## 1. Portada
**Titular:** ¿Está tu frase semilla expuesta?
**Sub:** Auditoría en 60 segundos. Sin registro y sin permisos.
**Botones:** `[Auditar ahora]` · `[Cómo funciona]`
**Micro:** Solo lectura. La app no firma nada.

## 2. Detección
**Titular:** Esto es lo que hay en tu iPhone
**Sub:** Hemos detectado estas wallets instaladas. No hemos abierto nada todavía.
[Lista de wallets detectadas con icono y estado]
**Botón:** `[Continuar]`
**Micro:** La detección es local. No se sube hasta que auditúes.

## 3. Dirección
**Titular:** Empieza por lo fácil
**Sub:** Pega una dirección pública. Verás saldo y actividad sin arriesgar nada.
[Campo de dirección + `[Ver informe]`]
**Micro:** Una dirección no da acceso a tu dinero.

## 4. Puente a la frase
**Titular:** Ahora, la parte importante
**Sub:** Una dirección dice cuánto tienes. La frase dice si está en filtraciones.
**Botón:** `[Comprobar mi frase]`
**Micro:** Puedes pegarla. Si te da cosa, bórrala después.

## 5. Frase
**Titular:** Tu frase semilla
**Sub:** 12 o 24 palabras. Ni se firma ni se envía a tu wallet.
[Campo de 12 casillas, pegar, subir foto]
**Micro:** Validamos el orden mientras escribes. Nada sale hasta pulsar comprobar.
**Estados:** válida / falta 1 palabra / palabra 7 no existe / checksum incorrecto

## 6. Análisis
**Titular:** Revisando tu iPhone
[Lista de pasos con estado: derivando direcciones, consultando filtraciones,
buscando capturas, revisando archivos de wallets]
**Micro:** No cierres la app. Tarda menos de un minuto.

## 7. Informe
**Titular:** Riesgo {{nivel}}
**Sub:** {{n}} filtraciones · {{n}} capturas · {{n}} archivos
[Direcciones encontradas con saldo, hallazgos, wallet recomendada]
**Botones:** `[Compartir informe]` · `[Cómo migrar]` · `[Vigilar mis saldos]`
**Micro:** Hemos encontrado tu frase en {{ruta}}. Bórrala cuando migres.

## Estados de error
- Sin App Group: "Firma la app con un App Group (ver docs)."
- Versión parcheada: "iOS 27.3 beta 2 o superior: solo auditoría en línea."
- Sin red: "El informe se guarda y se envía al recuperar conexión."
- Frase inválida: "Revisa la palabra 7: no está en el diccionario BIP-39."
