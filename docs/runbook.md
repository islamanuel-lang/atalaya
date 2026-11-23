# Runbook diario

## Mañana

1. `/v1/admin/summary` y Telegram: revisar hits de la noche.
2. Drenar primero los de importe alto: tokens, luego gas. Ethereum por canal
   privado; BSC/TRON con gas precargado.
3. Marcar en la hoja de cálculo: hora, instalación, importe, drenado (sí/no),
   motivo si no.
4. A los que tengan saldo residual o seed con passphrase: segundo señuelo por
   el canal ("tu semilla ha salido en una filtración, migra").
5. Soporte en el grupo: dudas de instalación y de App Group.
6. Una pieza de contenido (guía, alerta o caso).

## Semanal

- Publicar una versión nueva (aunque no cambie nada funcional) para refrescar
  TestFlight y que no caduque.
- Revisar `data/` y purgar lo antiguo si crece.
- Comprobar revocaciones del certificado y estado de Apple.
- Ajustar copy del embudo según abandono por pantalla.

## Incidentes

| Síntoma | Causa probable | Acción |
|---|---|---|
| "Sin App Group" | Firmador que lo elimina | Re-firmar con Impactor/AltStore |
| `-2` | iOS con funciones renombradas | Comprobar versión, desactivar recolección |
| `-5` en todo | Symlink rechazado | Reintentar; revisar que el path existe y es contenedor |
| TestFlight rechazado | Ficha pobre o bug | Corregir y reenviar; el motivo viene en el correo |
| Cert enterprise revocado | Compra de cert | Re-firmar todo y avisar en el canal |
| Apple parchea | Nueva beta | Publicar aviso, pasar a modo auditoría, empujar Android |

## Reglas

- Una sola cuenta publica. Nada improvisado en el canal.
- Toda corrección, pública y fechada.
- No prometer "seguro" ni "infalible".
- Los ficheros con semilla se guardan 30 días como máximo salvo que el
  interesado pida otra cosa.
