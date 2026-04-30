# Estado de migracion Flutter - CoolImport PCP

Actualizado: 2026-04-30
Avance funcional estimado: 98% (paridad funcional MIT cerrada; pendiente piloto real)

## Modulos migrados (operativos)

- Login corporativo con persistencia local de sesion.
- Home Admin / Operario con lenguaje visual unificado.
- Guardas de autenticacion para todo el enrutamiento interno:
  - Todo modulo distinto de `/login` exige sesion activa.
  - `/admin_home`, `/admin_users`, `/telemetria_operativa` protegidas por rol.
  - Bloqueo de acceso con pantalla corporativa para perfiles no autorizados.
- Tablero visual de estado de migracion en app (`/estado_migracion`) con porcentaje y estimacion.
- Consulta almacen (`/consulta_almacen`).
- Historial (`/consulta_historial`).
- Consulta stock PCP (`/consulta_pcp`) con parser QR robusto.
- Salida de almacen:
  - Validacion previa (`/movimiento_restringido_salida`) y envio seguro.
  - Scanner QR por camara.
  - Reglas MIT 1:1 por ubicacion (VENTA/TEÑIDO/DEVOLUCION) con campos obligatorios dinamicos.
  - Catalogos de destino por `/read_column` (columnas 13/14 de `datosKardex`) con fallback robusto.
  - Cola offline + telemetria de reintentos.
- Reingreso de almacen:
  - Validacion previa (`/movimiento_restringido`).
  - Carga de taras (`/datos_tara`).
  - Envio legacy a Google Forms (mapeo `entry.*`).
  - Cola offline + telemetria de reintentos.
- Inventario cero:
  - Verificacion de PCP (`/api/verificar_pcp/<codigo>`).
  - Registro en backend (`/api/inventario_cero`).
- Impresion de etiquetas locales:
  - Generacion PDF (`/generate_pdf`).
  - Impresion Zebra (`/imprimir`).
  - Fallback offline con cola persistente local.
  - Generacion de Kardex (`/generar_kardex`) por material/titulo/color.
  - Aplicacion del Kardex generado a la vista previa y QR de hilos antes de imprimir.
- Gestion stock telas:
  - Ingreso (`/registrar_ingreso_tela`).
  - Validacion de rollo (`/validar_rollo_despacho`).
  - Impresion local despacho (`/imprimir_despacho`).
  - Fallback offline con cola persistente para despacho.
  - Telemetria operativa de cola y reintentos.
- Urdido:
  - Escaneo y precarga (`/urdido_scan`).
  - Registro productivo (`/urdido_send`).
  - Catalogos (`/obtener_datos_generales`).
  - Cola offline + telemetria de reintentos.
  - Historial tabular por urdidora (`/urdido_historial_tabla`).
  - Resumen de mis registros (`/urdido_historial`).
- Engomado:
  - Vinculo con urdido (`/engomado_urdido_search`).
  - Registro por tipo de proceso (`/engomado_data`).
  - Cola offline + telemetria de reintentos.
- Telares:
  - Escaneo/precarga (`/telar_search`).
  - Registro de primer corte y nuevo corte (`/telar_send`).
  - Cola offline + telemetria de reintentos.
- Ingreso Telar (legacy MIT):
  - Carga de progreso por operario (`/telar_cargar_progreso`).
  - Autocompletado de articulo por telar (`/telar_articulo_actual`).
  - Guardar progreso / completar (`/telar_ingreso`).
- Historial Telar:
  - Tabla con filtro por telar (`/telar_historial_tabla`).
  - Acceso desde Home y desde la pantalla de Telares.
- Historial Tela Cruda:
  - Consulta por usuario activo (`/consulta_historial_telacruda`).
  - Orden y campos MIT: Cod Tela, OP, Articulo, Telar, Plegador, CC, Metro, Peso, Fecha Revisado, Rendimiento y Validacion.
  - Vista responsive: tabla en tablet/ancho y tarjetas legibles en celular.
- Historial Administrativo:
  - Carga de usuarios por `/read_column?sheet=datos&column=8`.
  - Consulta por Apps Script legacy de `HistorialAdmin`.
  - Tabla/tarjetas con Fecha, Hora, CKardex, Codigo, Almacen, Ubicacion y Movimiento.
- Cambio almacen (telar):
  - Parseo QR legacy 12/14/16 campos con fallback defensivo.
  - Destino dinamico por almacen (`PLANTA 1/2/3/TINTORERIA`).
  - Envio a Google Forms legacy (Screen5) + cola offline persistente.
- Cambio ubicacion (hilos):
  - Parseo QR 14/16 campos con soporte de kardex opcional.
  - Consulta de ultima ubicacion via `/almacen_ubicacion`.
  - Envio a Google Forms legacy (Screen6) + cola offline persistente.
- Gestion administrativa de usuarios:
  - Busqueda de usuario (`/admin_users`).
  - Alta de usuario (`/new_users`).
  - Edicion y eliminacion (`/admin_users` con payload legacy).
  - Confirmaciones operativas y validaciones inline.
- Editar proveedor:
  - Busqueda de codigo por proveedor/material/titulo (Apps Script legacy).
  - Carga de taras por codigo.
  - Actualizacion de taras (`tara_cono`, `tara_bolsa`, `tara_caja`, `tara_saco`).
- Agregar proveedor:
  - Registro en Google Sheets (`tablaProveedor`) via service account.
  - Fallback de credencial por asset o `--dart-define`.
  - Cola offline + telemetria de reintentos.
- Ingreso telas (movimientoTelas, modo nuevo):
  - Generacion de codigo legado (`T<numTelar>F<ddMMyy>-<correlativo>`).
  - Registro de corte en Google Forms legacy (`entry.*` historico).
  - Generacion QR de tela 8 campos + registro local (`/generate_pdf`) + impresion (`/imprimir`).
  - Catalogos por `/obtener_datos_generales` con fallback manual si no hay lista.
  - Modo editar legacy no expuesto por decision funcional: evita modificar registros historicos de `IngresoTela` desde Flutter durante el piloto.
- Contenedor:
  - Parser QR legacy 16 campos.
  - Calculo de bobinas/pesos y envio a Google Forms.
  - Actualizacion de stock via `/actualizar_datos`.
  - Cola offline + telemetria de reintentos.
- Monitor de salud de API local de impresion (`/health`).
- Configuracion admin de endpoints locales:
  - `API impresion local` editable en `/local_api_settings`.
  - `API local telares` editable para escenario hibrido local/cloud.
  - Fallback automatico de host para impresion y visibilidad del host activo.
- Telares con estrategia dual:
  - Primer intento por endpoint local configurable.
  - Fallback automatico a PythonAnywhere si el host local no responde.
- Sincronizacion automatica de colas al iniciar app, al volver a foreground y por ciclos periodicos.
- Panel de telemetria operativa para soporte en planta (`/telemetria_operativa`).
- Tablero de salida a planta `GO/NO-GO` (`/release_readiness`) con checklist persistente.
- Hardening de credenciales Google Sheets para release:
  - Soporte `GOOGLE_SHEETS_SA_B64` / `GOOGLE_SHEETS_SA_JSON`.
  - Bloqueo de credenciales embebidas en release salvo override controlado.
- Script de preflight tecnico para piloto: `scripts/preflight_pilot_check.ps1`.
- Runbook operativo de despliegue en planta: `docs/pilot_runbook.md`.

## En curso

- Piloto en red real de planta (validar cola + impresoras Zebra/Epson + rutas de produccion).

## Pendientes criticos

- Piloto operativo en planta con validacion funcional de `admin_users` (alta/edicion/baja).
- Validar `HistorialAdmin`, `Historial Tela Cruda` y `/generar_kardex` con usuarios reales y red de planta.
- Pruebas de regresion cruzadas de permisos y navegacion por rol en tablets MDM.

## Riesgos activos

- Flujo legacy de reingreso depende de Google Forms con mapeo de `entry.*` historico.
- Operacion offline extendida a toda la malla productiva; falta validar estabilidad de reintentos largos en turnos completos.
- Gestion de credenciales de Google Sheets en despliegue MDM (evitar exponer secretos en build).
- Faltan pruebas de integracion en red real de planta para impresion y despacho.

## Siguiente bloque recomendado

1. Ejecutar piloto operativo en planta (inventario + produccion + admin_users + nuevos modulos legacy migrados).
2. Cerrar pruebas end-to-end de colas/reintentos con caidas de red y recuperacion automatica.
3. Ejecutar `docs/release_pilot_checklist.md` y desplegar por anillos en tablets MDM.
4. Congelar baseline v2 Flutter y dejar App Inventor en modo respaldo temporal.
