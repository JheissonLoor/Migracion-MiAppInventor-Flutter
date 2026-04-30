# Checklist de salida a planta - Flutter PCP

Actualizado: 2026-04-30

Referencia operativa detallada: `docs/pilot_runbook.md`

## 1) Preflight tecnico

- [ ] Ejecutar `scripts/preflight_pilot_check.ps1` y revisar `docs/reports/preflight_latest.md`.
- [ ] `flutter clean && flutter pub get` completado sin errores.
- [ ] `dart analyze` sin errores (solo infos conocidos).
- [ ] `flutter test` en verde.
- [ ] Build `app-debug.apk` generado y firmado para entorno piloto.
- [ ] API principal accesible desde tablet (`/inicio_sesion`, `/consulta_pcp`).
- [ ] API principal valida `/consulta_historial_telacruda` y `/generar_kardex`.
- [ ] API local accesible en red de planta (`192.168.1.34:5001/health`).
- [ ] Credencial Google Sheets validada para `Agregar proveedor` (sin exponer secreto en APK release).

### Credenciales Google Sheets (release)

- Recomendado: inyectar secreto en build y no embeder JSON real en assets.
- Ejemplo:
  - `flutter build apk --release --dart-define=GOOGLE_SHEETS_SA_B64=<BASE64_JSON>`
- Solo para emergencia controlada:
  - `--dart-define=ALLOW_EMBEDDED_SHEETS_CREDENTIALS=true`

## 2) Validacion funcional critica

- [ ] Login y ruteo por rol (ADMIN/PCP vs Operario).
- [ ] Guardas de ruta activas (bloqueo de acceso sin sesion o sin rol).
- [ ] Salida/Reingreso con flujo online y cola offline.
- [ ] Urdido/Engomado/Telares con cola y reintentos.
- [ ] Gestion stock telas (ingreso + despacho + impresion local).
- [ ] Ingreso telas + Contenedor (QR 14/16, calculos y actualizacion `/actualizar_datos`).
- [ ] Historial Tela Cruda carga datos reales de `IngresoTela` por usuario.
- [ ] Historial Administrativo carga usuarios y movimientos por Apps Script legacy.
- [ ] Actualizar Etiqueta genera Kardex y aplica el codigo al QR de hilos antes de imprimir.
- [ ] Agregar proveedor (Google Sheets) + Editar proveedor (Apps Script legacy).
- [ ] Administrar usuarios: buscar, crear, editar y eliminar.

## 3) Pruebas en campo (turno real)

- [ ] 1 turno completo en modo normal con al menos 2 operarios.
- [ ] 1 prueba controlada sin red para validar encolado.
- [ ] Reconexion y drenado automatico de colas validado.
- [ ] Impresion Zebra y Epson validada desde tablets piloto.
- [ ] Telemetria operativa revisada por soporte de turno.

## 4) Despliegue por anillos (MDM Headwind)

- [ ] Anillo 1: 1-2 tablets de supervisores.
- [ ] Anillo 2: 4-6 tablets de operacion critica.
- [ ] Anillo 3: despliegue total.
- [ ] Congelar version estable de rollback (APK anterior).

## 5) Criterios de aceptacion para pasar a produccion total

- [ ] 0 caidas bloqueantes en 3 dias continuos.
- [ ] Tasa de reintento de colas dentro de rango esperado.
- [ ] Sin perdida de datos en reconexion.
- [ ] Sin incidencias de permisos por rol.
- [ ] Mesa PCP valida resultados de inventario y produccion.
- [ ] Tablero `/release_readiness` en estado GO al cierre de turno.

## 6) Plan de rollback inmediato

- [ ] Mantener APK legacy instalado en tablets criticas.
- [ ] Si hay incidente P1: volver a APK anterior por MDM.
- [ ] Mantener backend y Google Sheets sin cambios durante rollback.
- [ ] Registrar incidente con hora, modulo y payload para correccion.
