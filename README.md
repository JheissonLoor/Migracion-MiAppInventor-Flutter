# CoolImport PCP - Migracion industrial de MIT App Inventor a Flutter

[![Flutter CI](https://github.com/JheissonLoor/Migracion-MiAppInventor-Flutter/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/JheissonLoor/Migracion-MiAppInventor-Flutter/actions/workflows/flutter-ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-Android%20Industrial-02569B?logo=flutter&logoColor=white)
![Material 3](https://img.shields.io/badge/UI-Material%203%20Enterprise-1E4FD7)
![Offline First](https://img.shields.io/badge/Resiliencia-Offline%20First-0F766E)
![Legacy Safe](https://img.shields.io/badge/Migracion-Legacy%20Safe-111827)
![QR](https://img.shields.io/badge/QR-14%2F16%2F19%20campos-F59E0B)

Aplicacion Flutter para modernizar un sistema industrial textil originalmente construido en MIT App Inventor. El proyecto esta orientado a tablets Android en planta, mantiene compatibilidad con backend legacy y agrega una experiencia corporativa mas estable, entendible y preparada para operacion real.

> Caso de estudio: migracion incremental de una app productiva sin detener operaciones, sin cambiar backend y con MIT App Inventor como respaldo durante el piloto.

<p align="center">
  <img src="assets/images/hero_login.png" alt="CoolImport PCP - Login corporativo" width="780">
</p>

---

## Resumen para evaluadores

| Dimension | Resultado tecnico |
|---|---|
| Dominio | Inventario textil, produccion, stock, QR, despacho, trazabilidad e impresion |
| Plataforma | Flutter Android para tablets industriales gestionadas por MDM |
| Migracion | MIT App Inventor -> Flutter con rollout gradual y rollback operativo |
| Backend | Flask/PythonAnywhere, Supabase, Google Sheets y Apps Script sin cambios obligatorios |
| API local | Flask Windows en red de planta para PDF, Zebra y Epson |
| Estado | Paridad funcional alta; pendiente piloto final en red real de planta |
| Calidad | CI, `dart analyze`, `flutter test`, tests de contratos, parsers y colas offline |

Este repositorio demuestra trabajo real de modernizacion: entender un sistema legacy en produccion, conservar contratos existentes, reducir riesgo operativo y construir una app Flutter mantenible para varios anos.

---

## Por que este proyecto importa

El sistema original ya era usado por operarios en planta. La migracion no podia romper inventario, stock, impresion ni formularios existentes. Por eso la estrategia fue construir Flutter como una capa moderna encima de los contratos actuales.

Restricciones principales:

- No modificar endpoints Flask existentes.
- No cambiar Google Sheets ni Google Forms productivos.
- No detener operaciones.
- No hacer migracion Big Bang.
- Mantener MIT App Inventor como respaldo temporal.
- Soportar QR antiguos ya impresos y QR nuevos generados durante la migracion.
- Trabajar con red de planta, impresoras locales y tablets administradas.

---

## Senales tecnicas fuertes

- **Migracion legacy real:** se analizaron pantallas MIT App Inventor y se replico comportamiento critico en Flutter.
- **Contratos protegidos:** payloads y endpoints legacy centralizados para evitar errores por nombres inconsistentes.
- **QR robusto:** parsers para formatos de 6, 8, 14, 16 y 19 campos, incluyendo comas internas y Kardex opcional.
- **Operacion offline:** colas persistentes para movimientos, produccion, despacho e impresion.
- **UX industrial:** pantallas redisenadas con Material 3, formularios guiados, estados claros y lenguaje visual corporativo.
- **API local resiliente:** deteccion de salud, fallback de host e integracion con impresion Zebra/Epson.
- **Control de riesgo:** runbook, checklist GO/NO-GO, despliegue por anillos y rollback.
- **Seguridad de repositorio:** credenciales excluidas, plantillas `.example` y checklist de publicacion segura.

---

## Stack tecnico

| Capa | Tecnologia / decision |
|---|---|
| UI | Flutter, Material 3, diseno enterprise para planta |
| Estado | Riverpod / StateNotifier por modulo |
| Networking | Dio, timeouts, errores normalizados, datasources por dominio |
| Persistencia | SharedPreferences como reemplazo controlado de TinyDB |
| QR | `mobile_scanner`, `qr_flutter`, parsers defensivos |
| Offline | Colas persistentes con reintentos y telemetria operacional |
| Backend | Flask REST, PythonAnywhere, Supabase, Google Sheets, Apps Script |
| Impresion | API local Flask, PDF, Zebra ZD230, Epson L4260 |
| QA | Tests unitarios/contratos, analyzer, GitHub Actions |

---

## Arquitectura

```text
lib/
  core/
    config/        # entorno, URLs, constantes y flags operativos
    contracts/     # rutas y payloads legacy centralizados
    network/       # cliente HTTP, timeouts, API local y errores
    storage/       # persistencia local tipo TinyDB
    theme/         # sistema visual corporativo Material 3
    utils/         # parsers QR, builders y helpers
  data/
    datasources/   # REST, Apps Script, Sheets y API local
    models/        # DTOs, respuestas, payloads y colas offline
  presentation/
    providers/     # estado Riverpod por pantalla/modulo
    screens/       # pantallas por dominio funcional
    widgets/       # componentes reutilizables enterprise

test/
  core/            # contratos, parsers y reglas de negocio
  data/            # modelos, colas y compatibilidad legacy

docs/
  arquitectura, piloto, seguridad, auditoria MIT vs Flutter y runbooks
```

Principios aplicados:

- **Backend intacto:** Flutter se adapta al sistema existente, no al reves.
- **Dominio separado:** UI, estado, datos y contratos no estan mezclados.
- **Errores visibles:** fallos de red, QR incompleto y API local offline se muestran como estados operativos.
- **Operarios primero:** pantallas con flujo guiado, botones contextuales y menor carga cognitiva.
- **Preparado para soporte:** telemetria de colas, checks de API y documentacion de piloto.

---

## Modulos migrados

| Modulo | Estado | Valor tecnico |
|---|---:|---|
| Login y sesion | Completo | Persistencia local, rol, navegacion segura, UI enterprise |
| Home Admin / Operario | Completo | Accesos por rol y lenguaje visual unificado |
| Consulta Stock PCP | Completo | Parser QR 14/16/19 campos, Kardex opcional y consulta legacy |
| Salida / Reingreso Almacen | Completo | Reglas MIT, ubicacion operativa, validaciones y cola offline |
| Cambio Almacen / Ubicacion | Completo | QR legacy, Google Forms y proteccion contra doble envio |
| Inventario Cero | Completo | Verificacion y registro controlado |
| Gestion Stock Telas | Completo | Ingreso, despacho, QR, carrito, impresion y cola offline |
| Ingreso Telas | Completo | Formulario moderno, modo nuevo y payload legacy |
| Impresion Etiquetas | Completo | API local, PDF, QR, Kardex, Zebra/Epson y fallback offline |
| Produccion | Completo | Urdido, engomado, telares, ingreso telar y corte de rollo |
| Historiales | Completo | Admin, Telar, Urdido, Tela Cruda y general |
| Usuarios / Proveedores | Completo | CRUD compatible con backend legacy |
| Release Readiness | Completo | Checklist GO/NO-GO para piloto |
| Telemetria Operativa | Completo | Estado de colas, reintentos y errores |

---

## Integraciones legacy soportadas

Endpoints y contratos relevantes:

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

El objetivo no fue reescribir el backend, sino construir una app Flutter confiable que respete lo que ya funciona en produccion.

---

## QR y validacion de datos

Formatos soportados:

| Tipo | Campos | Uso |
|---|---:|---|
| Tela cruda | 8 | Ingreso, despacho e impresion |
| Hilos legacy | 14 / 16 / 19 | Stock PCP, almacen, produccion |
| Legacy simple | 6 | Compatibilidad historica |

Casos reales cubiertos:

- QR con comas internas en articulo/color.
- QR antiguos sin Kardex.
- Respuestas backend con offsets heredados de MIT.
- Codigo de tela incompleto, por ejemplo `T20F040626-1-`.
- Normalizacion a codigo completo cuando existe correlativo: `T20F040626-1-12`.
- Prevencion de registros duplicados por doble envio o lectura incompleta.

---

## Offline first operativo

Las operaciones criticas no dependen de que la red este perfecta todo el tiempo. La app mantiene colas persistentes para:

- Impresion Zebra/Epson.
- Despachos de telas.
- Salida y reingreso de almacen.
- Produccion: urdido, engomado y telares.
- Proveedores y movimientos legacy.

Cada job conserva:

```text
payload original
estado
intentos
ultimo error
fecha de creacion
fecha de ultimo reintento
```

Esto permite auditar fallos, reintentar al recuperar red y reducir perdida de datos en planta.

---

## Seguridad y publicacion

Este repositorio esta preparado como version publica saneada.

- No contiene credenciales reales.
- No versiona service accounts productivas.
- La credencial de Google Sheets se inyecta por `--dart-define`.
- Archivos sensibles estan documentados en `SECURITY.md`.
- Existe checklist previo a push en `docs/security_publish_checklist.md`.

Revision rapida antes de publicar cambios:

```bash
git status
rg -n --hidden --glob '!build/**' --glob '!.dart_tool/**' --glob '!.git/**' "BEGIN PRIVATE KEY|private_key|client_email|ghp_|github_pat_|AIza" .
flutter test
dart analyze
```

---

## Calidad y validacion

Comandos principales:

```bash
flutter pub get
dart analyze
flutter test
```

Estado validado del proyecto:

- `flutter test`: 61 tests en verde.
- `dart analyze`: sin errores bloqueantes; solo infos de estilo heredadas.
- GitHub Actions: validacion automatica en push y pull request.

Areas cubiertas por tests:

- Parsers QR y normalizacion de datos legacy.
- Contratos de payload para endpoints existentes.
- Modelos de colas offline y telemetria.
- DTOs de historial y respuestas backend.
- Bootstrap basico de la app.

---

## Ejecutar localmente

```bash
flutter pub get
flutter test
dart analyze
flutter run
```

Build release con credencial inyectada:

```bash
flutter build apk --release --dart-define=GOOGLE_SHEETS_SA_B64=<BASE64_JSON>
```

> La credencial real nunca debe copiarse al repositorio.

---

## Ruta recomendada para revisar el codigo

Si eres reclutador tecnico o evaluador y tienes poco tiempo:

1. `docs/recruiter_case_study.md` - historia tecnica y decisiones clave.
2. `lib/core/contracts/api_contracts.dart` - compatibilidad legacy.
3. `lib/core/utils/` - parsers QR y tolerancia a datos reales.
4. `lib/data/models/*queue*` - offline first aplicado a operaciones criticas.
5. `lib/presentation/screens/auth/login_screen.dart` - UI enterprise responsive.
6. `docs/mit_flutter_gap_audit_2026-04-28.md` - auditoria MIT vs Flutter.
7. `test/core` y `test/data` - evidencia de pruebas sobre contratos reales.

---

## Documentacion del proyecto

- `docs/recruiter_case_study.md`: caso de estudio para portafolio y entrevistas.
- `docs/migration_status.md`: estado funcional de la migracion.
- `docs/mit_flutter_gap_audit_2026-04-28.md`: auditoria MIT vs Flutter.
- `docs/release_pilot_checklist.md`: checklist para salida a planta.
- `docs/pilot_runbook.md`: runbook operativo de piloto.
- `docs/architecture_decisions.md`: decisiones tecnicas principales.
- `docs/portfolio_review_guide.md`: guia para evaluadores tecnicos.
- `docs/security_publish_checklist.md`: control de seguridad antes de publicar.

---

## Roadmap inmediato

1. Ejecutar piloto en tablets reales dentro de la red de planta.
2. Validar impresion local Zebra/Epson con IP productiva.
3. Probar caida y recuperacion de red con colas offline.
4. Desplegar por anillos mediante MDM.
5. Congelar baseline Flutter y mantener MIT App Inventor como respaldo temporal.
6. Reemplazar logs `print` por logger estructurado.
7. Convertir infos de analyzer en deuda tecnica planificada.

---

## Nota publica

Este repositorio no incluye infraestructura productiva, credenciales, datos sensibles ni archivos legacy privados. El objetivo publico es mostrar arquitectura, migracion, UI, resiliencia operativa y criterio tecnico aplicado a un sistema empresarial real.
