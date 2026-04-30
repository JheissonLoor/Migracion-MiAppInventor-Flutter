# Migracion MIT App Inventor a Flutter - CoolImport PCP

Aplicacion Flutter empresarial para modernizar un sistema industrial textil originalmente desarrollado en MIT App Inventor. El objetivo del proyecto es mantener compatibilidad operacional con el backend legacy mientras se entrega una experiencia Android moderna, robusta y preparada para tablets en planta.

> Caso de estudio tecnico: migracion incremental de una app en produccion, sin modificar backend, Google Sheets, PythonAnywhere ni la API local de impresion.

## Resumen ejecutivo

- **Dominio:** inventario textil, produccion, QR, despacho, historial e impresion.
- **Plataforma objetivo:** Android tablets industriales administradas por MDM.
- **Migracion:** MIT App Inventor -> Flutter + Riverpod + Dio.
- **Backend:** Flask/PythonAnywhere, Google Sheets, Supabase y API local de impresion.
- **Estrategia:** paridad funcional, rollout por anillos y rollback seguro.
- **Estado:** paridad funcional MIT cerrada a nivel app; pendiente piloto completo en red real de planta.

## Stack

| Capa | Tecnologia |
|---|---|
| UI | Flutter, Material 3, diseno industrial corporativo |
| Estado | Riverpod / StateNotifier |
| Networking | Dio con timeouts, retries y manejo unificado de errores |
| Persistencia local | SharedPreferences como reemplazo de TinyDB |
| QR | `mobile_scanner`, parser QR robusto y `qr_flutter` |
| Offline | Colas persistentes para impresion, despacho y movimientos criticos |
| Integraciones | Flask REST, Google Sheets, Supabase, Apps Script, API local Zebra/Epson |
| QA | `flutter test`, `dart analyze`, tests unitarios de contratos y parsers |

## Lo que demuestra este proyecto

- Migracion gradual de un sistema legacy **sin detener operacion**.
- Conservacion de contratos reales usados por MIT App Inventor.
- Arquitectura Flutter mantenible, separando UI, providers, datasources, modelos y contratos.
- Manejo de escenarios industriales: red inestable, doble envio, impresion local, QR legacy y fallback offline.
- Documentacion operativa para piloto, rollback, release readiness y despliegue por MDM.

## Modulos migrados

- Login corporativo y ruteo por rol.
- Home Admin / Operario con lenguaje visual unificado.
- Consulta de stock PCP con parser QR 14/16/19 campos.
- Salida y reingreso de almacen.
- Cambio de almacen y cambio de ubicacion.
- Inventario cero.
- Gestion stock telas.
- Ingreso de telas y generacion/impresion QR.
- Impresion de etiquetas con cola offline y `/generar_kardex`.
- Urdido, Engomado, Telares e Ingreso Telar.
- Historial general, Historial Admin, Historial Telar, Historial Urdido e Historial Tela Cruda.
- Administracion de usuarios y proveedores.
- Monitor de API local, telemetria operativa y release readiness.

## Arquitectura

```text
lib/
  core/
    config/        # constantes, entornos y contratos globales
    contracts/     # rutas y payloads legacy centralizados
    network/       # cliente HTTP principal y API local
    storage/       # persistencia local tipo TinyDB
    theme/         # sistema visual corporativo
    utils/         # parsers QR, builders y helpers
  data/
    datasources/   # acceso REST, Apps Script, Sheets y API local
    models/        # DTOs, payloads, colas offline
  presentation/
    providers/     # estado Riverpod por modulo
    screens/       # pantallas por dominio
    widgets/       # componentes reutilizables
test/
  core/            # parsers y contratos
  data/            # modelos y compatibilidad legacy
docs/
  piloto, migracion, auditoria MIT vs Flutter y release
```

## Compatibilidad legacy

La app conserva los endpoints y payloads utilizados por MIT App Inventor. Los nombres de campos legacy se centralizan en `lib/core/contracts/api_contracts.dart` para reducir errores por typos y facilitar auditoria.

Ejemplos de contratos soportados:

- `/inicio_sesion`
- `/consulta_pcp`
- `/stock_actual_pcp`
- `/movimiento_restringido`
- `/movimiento_restringido_salida`
- `/registrar_ingreso_tela`
- `/validar_rollo_despacho`
- `/consulta_historial_telacruda`
- `/generar_kardex`
- `/read_column`
- API local: `/health`, `/generate_pdf`, `/imprimir`, `/imprimir_despacho`

## Offline y resiliencia

El proyecto implementa colas persistentes para operaciones donde no se puede perder informacion:

- Impresion Zebra/Epson.
- Despachos de telas.
- Salida/reingreso de almacen.
- Produccion: urdido, engomado y telares.
- Proveedores y movimientos legacy.

Cada cola registra telemetria: intentos, reintentos, pendientes, ultimo error y ultimo drenado exitoso.

## Seguridad operacional

- No se versionan credenciales reales.
- Las credenciales de Google Sheets se inyectan por `--dart-define`.
- `assets/config/pcp_service_account.json` esta ignorado por Git.
- El archivo `assets/config/pcp_service_account.example.json` es solo plantilla.
- El repositorio publico no debe contener dumps de backend, keys ni archivos `.aia` con secretos.

## Ejecutar localmente

```bash
flutter pub get
flutter test
dart analyze
flutter run
```

Para build release con credencial inyectada:

```bash
flutter build apk --release \
  --dart-define=GOOGLE_SHEETS_SA_B64=<BASE64_JSON>
```

## Validacion

Ultima validacion local:

- `flutter test`: 55 tests en verde.
- `dart analyze`: sin errores; solo infos de estilo heredadas.

## Documentacion destacada

- `docs/migration_status.md`: estado funcional de la migracion.
- `docs/mit_flutter_gap_audit_2026-04-28.md`: auditoria MIT vs Flutter.
- `docs/release_pilot_checklist.md`: checklist para salida a planta.
- `docs/pilot_runbook.md`: runbook operativo.

## Roadmap inmediato

1. Piloto en tablets reales dentro de red de planta.
2. Validacion de impresion local Zebra/Epson.
3. Pruebas de caida y recuperacion de red.
4. Rollout por anillos mediante MDM.
5. Congelar baseline Flutter y dejar MIT App Inventor como respaldo temporal.

## Nota

Este repositorio esta preparado como caso de estudio tecnico y version publica saneada. La infraestructura productiva real, credenciales y datos sensibles deben administrarse fuera del repositorio.
