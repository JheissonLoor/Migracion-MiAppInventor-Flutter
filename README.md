# Migracion MIT App Inventor a Flutter - CoolImport PCP

[![Flutter CI](https://github.com/JheissonLoor/Migracion-MiAppInventor-Flutter/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/JheissonLoor/Migracion-MiAppInventor-Flutter/actions/workflows/flutter-ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-Android%20Industrial-02569B?logo=flutter&logoColor=white)
![Material 3](https://img.shields.io/badge/UI-Material%203%20Enterprise-1E4FD7)
![Offline First](https://img.shields.io/badge/Resiliencia-Offline%20First-0F766E)
![Legacy Migration](https://img.shields.io/badge/Migracion-MIT%20App%20Inventor%20to%20Flutter-111827)

Aplicacion Flutter empresarial para modernizar un sistema industrial textil originalmente construido en MIT App Inventor. El proyecto mantiene compatibilidad operacional con backend legacy, Google Sheets, Supabase, Apps Script y API local de impresion, mientras introduce una experiencia Android moderna para tablets usadas en planta.

> Caso de estudio tecnico: migracion incremental de una app productiva sin detener operaciones, sin modificar backend y con rollback operativo.

<p align="center">
  <img src="assets/images/hero_login.png" alt="CoolImport PCP login visual" width="720">
</p>

## Indice

- [Resumen ejecutivo](#resumen-ejecutivo)
- [Problema real](#problema-real)
- [Stack tecnico](#stack-tecnico)
- [Que demuestra este proyecto](#que-demuestra-este-proyecto)
- [Arquitectura](#arquitectura)
- [Modulos migrados](#modulos-migrados)
- [Compatibilidad legacy](#compatibilidad-legacy)
- [QR, datos y validacion](#qr-datos-y-validacion)
- [Offline y resiliencia](#offline-y-resiliencia)
- [Seguridad operacional](#seguridad-operacional)
- [Calidad y validacion](#calidad-y-validacion)
- [Ejecutar localmente](#ejecutar-localmente)
- [Flujo Git recomendado](#flujo-git-recomendado)
- [Documentacion tecnica](#documentacion-tecnica)
- [Roadmap inmediato](#roadmap-inmediato)

## Resumen ejecutivo

| Area | Decision |
|---|---|
| Dominio | Inventario textil, produccion, stock, QR, despacho, historial e impresion |
| Plataforma | Android tablets industriales administradas por MDM |
| Migracion | MIT App Inventor a Flutter con rollout gradual |
| Backend | Flask/PythonAnywhere, Google Sheets, Supabase y Apps Script |
| API local | Flask Windows en red de planta para PDF, Zebra y Epson |
| Estado | Paridad funcional MIT cerrada a nivel app; pendiente piloto final en red real |
| Estrategia | Convivencia MIT + Flutter, anillos de despliegue y rollback seguro |

## Problema real

El sistema original opera todos los dias en planta. La migracion no podia ser un redisenio aislado ni un reemplazo completo de infraestructura. La restriccion principal fue mantener intactos:

- Endpoints Flask existentes.
- Google Sheets como base operacional.
- Google Forms y Apps Script.
- Supabase para usuarios/datos maestros.
- API local de impresion en red interna.
- Formatos QR legacy ya impresos y usados por operarios.

La solucion Flutter actua como una capa moderna de producto sobre contratos legacy existentes.

## Stack tecnico

| Capa | Tecnologia |
|---|---|
| UI | Flutter, Material 3, diseno industrial corporativo |
| Estado | Riverpod / StateNotifier |
| Networking | Dio con timeouts, normalizacion de errores y servicios por dominio |
| Persistencia local | SharedPreferences como reemplazo controlado de TinyDB |
| QR | mobile_scanner, qr_flutter y parsers legacy robustos |
| Offline | Colas persistentes para operaciones criticas |
| Integraciones | Flask REST, Google Sheets, Supabase, Apps Script, API local Zebra/Epson |
| QA | dart analyze, flutter test, tests de contratos, parsers y DTOs |
| CI | GitHub Actions con validacion automatica en push y pull request |

## Que demuestra este proyecto

- Migracion gradual de un sistema legacy sin detener operacion.
- Conservacion de contratos reales usados por MIT App Inventor.
- Arquitectura Flutter separada por UI, providers, datasources, modelos y contratos.
- Manejo de planta: red inestable, doble envio, impresion local, QR legacy y rollback.
- Diseno corporativo moderno para pantallas operativas de alto uso.
- Documentacion de piloto, release readiness y despliegue por anillos.

## Arquitectura

```text
lib/
  core/
    config/        # constantes, entorno y configuracion global
    contracts/     # rutas y payloads legacy centralizados
    network/       # cliente HTTP principal, timeouts y API local
    storage/       # persistencia local tipo TinyDB
    theme/         # sistema visual corporativo Material 3
    utils/         # parsers QR, builders y helpers
  data/
    datasources/   # REST, Apps Script, Sheets y API local
    models/        # DTOs, payloads y colas offline
  presentation/
    providers/     # estado Riverpod por modulo
    screens/       # pantallas por dominio
    widgets/       # componentes reutilizables
test/
  core/            # contratos y parsers
  data/            # modelos y compatibilidad legacy
docs/
  arquitectura, piloto, auditoria MIT vs Flutter y release
```

### Principios aplicados

- **Compatibilidad primero:** no se rompen endpoints ni nombres de payload legacy.
- **UI no acoplada al backend:** las pantallas consumen providers; los providers consumen datasources.
- **Contratos centralizados:** rutas y payloads viven en `lib/core/contracts/api_contracts.dart`.
- **Operacion segura:** operaciones criticas tienen proteccion contra doble envio y cola offline.
- **Observabilidad minima:** telemetria local de colas, reintentos y errores para soporte en planta.

## Modulos migrados

| Modulo | Estado | Enfoque tecnico |
|---|---:|---|
| Login y sesion | Completo | Persistencia local, rol, navegacion segura y UI enterprise |
| Home Admin / Operario | Completo | Accesos por rol y lenguaje visual unificado |
| Consulta Stock PCP | Completo | Parser QR 14/16/19 campos y consulta legacy |
| Salida / Reingreso Almacen | Completo | Contrato MIT, ubicacion operativa y cola offline |
| Cambio Almacen / Ubicacion | Completo | QR legacy, validacion y envio controlado |
| Inventario Cero | Completo | Flujo de conteo con validacion y estado de carga |
| Gestion Stock Telas | Completo | Ingreso, despacho y cola para impresion/despacho |
| Ingreso Telas | Completo | Formulario moderno manteniendo payload legacy |
| Impresion Etiquetas | Completo | API local, cola offline, QR y generacion Kardex |
| Urdido / Engomado / Telares | Completo | Produccion con fallback y cola offline |
| Historiales | Completo | Admin, Telar, Urdido, Tela Cruda y general |
| Usuarios / Proveedores | Completo | CRUD compatible con backend legacy |
| Release Readiness | Completo | Pantalla de verificacion previa a piloto |
| Telemetria Operativa | Completo | Estado de colas, reintentos y fallos |

## Compatibilidad legacy

La app conserva endpoints y payloads utilizados por MIT App Inventor. Los nombres de campos legacy se centralizan en `lib/core/contracts/api_contracts.dart` para reducir errores y facilitar auditoria.

Contratos soportados:

```text
/inicio_sesion
/consulta_pcp
/stock_actual_pcp
/movimiento_restringido
/movimiento_restringido_salida
/registrar_ingreso_tela
/validar_rollo_despacho
/consulta_historial_telacruda
/generar_kardex
/read_column
```

API local de impresion:

```text
/health
/generate_pdf
/imprimir
/imprimir_despacho
```

## QR, datos y validacion

Formatos QR soportados:

| Tipo | Campos | Uso |
|---|---:|---|
| Hilos extendido | 14 / 16 / 19 | Stock PCP, almacen, produccion |
| Telas | 8 | Ingreso, despacho, impresion |
| Legacy simple | 6 | Compatibilidad historica |

El parser evita errores frecuentes del entorno real:

- Comas internas en textos.
- Valores numericos con separadores distintos.
- QR antiguos sin Kardex.
- Respuestas backend con offsets legacy.
- Campos vacios que MIT toleraba y Flutter debe tolerar.

## Offline y resiliencia

El proyecto implementa colas persistentes para operaciones donde no se puede perder informacion:

- Impresion Zebra/Epson.
- Despachos de telas.
- Salida y reingreso de almacen.
- Produccion: urdido, engomado y telares.
- Movimientos legacy y proveedores.

Cada cola registra:

```text
pendientes
intentos
ultimo error
ultimo drenado exitoso
fecha de creacion
payload original
```

Esto permite que una tablet pueda seguir operando ante cortes temporales de red y reintentar cuando el servicio vuelva.

## Seguridad operacional

- No se versionan credenciales reales.
- Las credenciales de Google Sheets se inyectan por `--dart-define`.
- `assets/config/pcp_service_account.json` esta ignorado por Git.
- `assets/config/pcp_service_account.example.json` es solo plantilla.
- `temp/` y exports legacy con secretos quedan fuera del repositorio.
- El historial publico fue saneado antes de publicar.

Checklist rapido antes de publicar:

```bash
git status
git grep -n -I "BEGIN PRIVATE KEY\|private_key\|client_email\|ghp_\|github_pat_\|AIza" .
git diff --cached --name-only
```

## Calidad y validacion

Validacion actual:

```bash
flutter pub get
dart analyze
flutter test
```

Estado validado:

- `flutter test`: 55 tests en verde.
- `dart analyze`: sin errores; solo infos de estilo heredadas.
- GitHub Actions: CI activo en `master`.

Areas cubiertas por tests:

- Contratos legacy.
- Parsers QR.
- Modelos de cola offline.
- DTOs de historial.
- Bootstrap de app.

## Ejecutar localmente

```bash
flutter pub get
flutter test
dart analyze
flutter run
```

Build release con credencial inyectada:

```bash
flutter build apk --release \
  --dart-define=GOOGLE_SHEETS_SA_B64=<BASE64_JSON>
```

> Nota: la credencial real no debe copiarse al repositorio. Debe gestionarse como secreto fuera de Git.

## Flujo Git recomendado

Commits en espanol con convencion clara:

```bash
git add .
git commit -m "feat: agrega validacion de salida de almacen"
git push
```

Tipos recomendados:

```text
feat      nueva funcionalidad
fix       correccion de bug
docs      documentacion
test      pruebas
refactor  mejora interna sin cambiar comportamiento
style     cambios visuales o formato
chore     configuracion, CI o mantenimiento
security  seguridad
```

## Documentacion tecnica

- `docs/migration_status.md`: estado funcional de la migracion.
- `docs/mit_flutter_gap_audit_2026-04-28.md`: auditoria MIT vs Flutter.
- `docs/release_pilot_checklist.md`: checklist para salida a planta.
- `docs/pilot_runbook.md`: runbook operativo.
- `docs/architecture_decisions.md`: decisiones tecnicas principales.
- `docs/portfolio_review_guide.md`: guia para evaluadores tecnicos y recruiters.
- `docs/security_publish_checklist.md`: control de seguridad antes de publicar.

## Roadmap inmediato

1. Piloto en tablets reales dentro de red de planta.
2. Validacion de impresion local Zebra/Epson con IP productiva.
3. Pruebas de caida y recuperacion de red.
4. Rollout por anillos mediante MDM.
5. Congelar baseline Flutter y mantener MIT App Inventor como respaldo temporal.
6. Reemplazar logs `print` por logger estructurado.
7. Convertir infos de analyzer en deuda tecnica planificada.

## Nota publica

Este repositorio esta preparado como caso de estudio tecnico y version publica saneada. La infraestructura productiva real, credenciales, datos sensibles y archivos legacy con secretos deben administrarse fuera del repositorio.
