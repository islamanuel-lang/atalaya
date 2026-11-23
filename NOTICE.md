# Avisos y atribución

## worse_query

`ios/Atalaya/Core/Exploit/` contiene código de
[worse_query](https://github.com/forcequitOS/worse_query), Copyright (C) 2026
Taj C (forcequit), publicado bajo GPL-3.0-or-later.

Modificaciones de Atalaya:

- Resolución dinámica del App Group (`SecTaskCopyValueForEntitlement`).
- Comprobación de versión y de paths soportados antes de consumir el token.
- Empaquetado como framework de app y manejo de errores propio.

## Técnica

La técnica de escape de sandbox, la enumeración por inodos
(`fsgetpath`) y los flags de `containermanagerd` son obra de forcequit.
`Atalaya` no reclama autoría sobre ellos.

## Terceros

- Wordlist BIP-39: [bitcoin/bips](https://github.com/bitcoin/bips), dominio público.
- Tipografías Space Grotesk e Inter: SIL Open Font License 1.1.
- Cliente backend: express, ethers, @scure/bip39, @scure/bip32,
  @scure/btc-signer, @noble/hashes, bs58, tweetnacl.

Todo el proyecto se distribuye bajo GPL-3.0-or-later salvo donde se indique.
