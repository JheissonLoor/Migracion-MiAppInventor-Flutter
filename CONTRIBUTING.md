# Guia de contribucion

Este proyecto sigue una regla simple: primero compatibilidad operativa, luego mejora visual, luego refactor interno. La app replica flujos MIT App Inventor que ya operan en planta; por eso cualquier cambio debe proteger datos, endpoints y payloads legacy.

## Flujo recomendado

```bash
git status
git pull
git checkout -b feat/nombre-corto
git add .
git commit -m "feat: describe el cambio en espanol"
git push -u origin feat/nombre-corto
```

## Convencion de commits

Formato:

```text
<tipo>: <accion clara en espanol>
```

Ejemplos correctos:

```text
feat: agrega validacion de salida de almacen
fix: corrige parser QR de stock PCP con 19 campos
docs: mejora guia de piloto en tablets
refactor: centraliza payload legacy de impresion
test: cubre cola offline de despacho
security: excluye credenciales locales del repositorio
```

Tipos permitidos:

| Tipo | Uso |
|---|---|
| feat | Nueva funcionalidad visible |
| fix | Correccion de bug |
| docs | Documentacion |
| test | Pruebas |
| refactor | Cambio interno sin modificar comportamiento |
| style | UI, estilos o formato visual |
| chore | Configuracion, mantenimiento o CI |
| perf | Rendimiento |
| security | Seguridad |

## Reglas de seguridad

Antes de commitear:

```bash
git status
git diff --cached --name-only
git grep -n -I "BEGIN PRIVATE KEY\|private_key\|client_email\|ghp_\|github_pat_\|AIza" .
```

No se permite versionar:

- `assets/config/pcp_service_account.json`
- Archivos `caramel-world-*.json`
- Archivos `pruebacoolimportbusqueda-*.json`
- Exports AIA con credenciales.
- Dumps de Google Sheets productivos.
- Tokens, API keys o secrets.

## Checklist antes de Pull Request

- [ ] `flutter pub get` ejecutado.
- [ ] `dart analyze` sin errores.
- [ ] `flutter test` en verde.
- [ ] No se modificaron endpoints legacy sin justificacion.
- [ ] No se cambiaron nombres de campos de payload legacy.
- [ ] No se agregaron credenciales reales.
- [ ] Se probo el flujo principal afectado.
- [ ] Se documento cualquier diferencia frente a MIT App Inventor.

## Criterio de calidad

Una pantalla nueva debe cumplir:

- UI responsive para celular y tablet.
- Estados de carga, exito y error visibles.
- Proteccion contra doble envio.
- Errores integrados en pantalla, no solo SnackBar.
- Contratos centralizados en `api_contracts.dart` si toca backend.
- Tests para parsers, payloads o modelos cuando aplique.
