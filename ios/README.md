# iOS

Proyecto XcodeGen. No abras `Atalaya.xcodeproj` a mano: se genera.

```bash
brew install xcodegen
xcodegen generate
open Atalaya.xcodeproj
```

- Bundle ID y App Group se cambian en `project.yml` y en
  `Atalaya/Resources/Atalaya.entitlements`.
- El App Group se resuelve en ejecución (`AQCurrentAppGroup`), nunca se
  hardcodea en la lógica.
- `Atalaya/Core/Exploit/` es código GPL de `worse_query`.
- El API se configura en Ajustes o con `atalaya.apiBase` en UserDefaults.

Puntos delicados al compilar:

- `SWIFT_OBJC_BRIDGING_HEADER` apunta a `Resources/Bridging-Header.h`, que
  importa las cabeceras con ruta relativa.
- `InstalledApps.m` usa `LSApplicationWorkspace` (API privada, admitida).
- `AppGroup.m` declara `SecTask` a mano: no hay cabecera pública.
- La recolección necesita App Group autorizado en el perfil; si no, `-1`.

Lectura de capturas: se intenta `/private/var/mobile/Media/DCIM`. No está
verificado en todas las versiones; el log lo refleja y la app sigue si falla.
