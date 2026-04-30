# Auditoria MIT vs Flutter (2026-04-28)

Fuente evaluada:
- MIT App Inventor: `c:\CoolImport\Arregal aqui de mit app inventor\PCPDev_APP_v5_FIXED.aia`
- Flutter: rutas activas en `lib/main.dart` y modulos en `lib/presentation/screens`

## Resumen ejecutivo

- Pantallas MIT detectadas: **29**
- Equivalencia Flutter:
  - **25 completas**
  - **3 parciales**
  - **0 faltantes**

Conclusión:
- El nucleo operativo principal (login, salida/reingreso, inventario, produccion, telas, admin usuarios/proveedores) esta migrado.
- Ya no quedan pantallas MIT sin ruta Flutter. Lo pendiente queda como **paridad fina** en modulos parciales y validacion en planta.

## Matriz por pantalla MIT

| MIT | Estado Flutter | Ruta / modulo Flutter | Nota |
|---|---|---|---|
| Screen1 | Completo | `/login` | Inicio de sesion |
| Screen2 | Completo | `/operario_home` | Menu operario |
| ScreenAdmin | Completo | `/admin_home` | Menu admin |
| Consulta_Almacen | Completo | `/consulta_almacen` | Consulta almacen |
| Historial | Completo | `/historial` | Historial general |
| Screen3 (Reingreso) | Completo | `/reingreso` | Flujo migrado con validacion |
| Screen4 (Salida) | Completo | `/salida_almacen` | Flujo MIT 1:1 en avance final |
| salidaAlmacenOp | Completo | `/salida_almacen` | Cubierto por flujo unificado |
| Screen5 (Traslado cajas) | Completo | `/cambio_almacen` | Flujo legacy migrado |
| Screen6 (Cambio ubicacion) | Completo | `/cambio_ubicacion` | Flujo legacy migrado |
| inventarioCero | Completo | `/inventario_cero` | Migrado |
| Urdido | Completo | `/urdido` | Migrado |
| Engomado | Completo | `/engomado` | Migrado |
| Telares | Completo | `/telares` | Migrado (hibrido local/cloud) |
| gestionStockTelas | Completo | `/gestion_stock_telas` | Migrado |
| movimientoTelas | Completo | `/ingreso_telas` | Migrado (corte + QR + impresion) |
| contenedorIngreso | Completo | `/contenedor` | Migrado |
| Admin_users | Completo | `/admin_users` | Migrado |
| agregarProveedor | Completo | `/agregar_proveedor` | Migrado |
| editarProveedor | Completo | `/editar_proveedor` | Migrado |
| screenTelas | Completo (fusionado) | Home admin/operario | Funciones distribuidas en modulos |
| inventarioPCP | Parcial | `/consulta_stock` | Equivalente funcional, no replica UI exacta |
| IngresoNuevo | Parcial | Provider existe, UI no expuesta | Existe `ingreso_telas_provider.dart`, falta ruta/pantalla productiva |
| registroItem | Completo | `/impresion_etiqueta` | Impresion + cola offline + `/generar_kardex` |
| CONSULTA_TELA_CRUDA | Completo | `/historial_tela_cruda` | Endpoint `/consulta_historial_telacruda` + vista responsive |
| HistorialAdmin | Completo | `/historial_admin` | `/read_column` + Apps Script legacy |
| HistorialTelar | Completo | `/historial_telar` | Tabla con filtro por telar |
| HistorialUrdido | Completo | `/historial_urdido` | Tabla con filtro por urdidora + resumen operario |
| IngresoTelar | Completo | `/ingreso_telar` | Carga progreso + articulo actual + guardar/completar |

## Endpoints MIT no cubiertos aun en Flutter

Detectados en MIT y no migrados por decision funcional:

- `/busqueda_tela_cruda`
- `/editar_tela_cruda`

Nota: `/busqueda_tela_cruda` y `/editar_tela_cruda` pertenecen al modo **Editar** de `movimientoTelas`. Ese modo queda fuera del alcance operativo actual porque el flujo requerido es **Nuevo**; no se expone edición para evitar cambios manuales sobre registros historicos de `IngresoTela`.

## Integraciones externas pendientes de paridad

- Google Apps Script de `HistorialAdmin` ya esta consumido por Flutter en `/historial_admin`.
- QuickChart en `registroItem`:
  - `https://quickchart.io/qr?...`
  - En Flutter ya hay generacion de QR local, pero no replica ese flujo exacto de endpoint.

## Riesgo operativo (priorizado)

1. **Bajo**: diferencia visual/UX en `inventarioPCP` vs `consulta_stock` (funcionalmente cercano).
2. **Bajo**: `HistorialAdmin`, `CONSULTA_TELA_CRUDA` y `/generar_kardex` requieren validacion en red real con datos actuales.

## Plan de cierre recomendado (orden de ejecucion)

### Bloque 1 (prioridad operativa)
1. Bloque `IngresoTelar` cerrado (screen + ruta + acceso desde Home).

### Bloque 2 (control y trazabilidad)
2. Bloque `HistorialTelar` + `HistorialUrdido` cerrado.
3. Bloque `HistorialAdmin` cerrado (script + selector de usuario).

### Bloque 3 (modulos especializados)
4. Bloque `CONSULTA_TELA_CRUDA` cerrado.
5. Bloque `registroItem` cerrado con `/generar_kardex` integrado.

### Bloque 4 (hardening final)
6. Checklist E2E por modulo en tablet real + red planta.
7. Cierre de gaps en `docs/migration_status.md` y `release_readiness`.

## Decisiones tecnicas sugeridas para seguir sin frenar produccion

- No tocar backend actual; solo consumir endpoints existentes.
- Mantener estrategia de fallback local/cloud ya usada en telares.
- Para cada nuevo modulo: incluir cola offline, bloqueo de doble envio y telemetria.
- Activar modulos nuevos por anillos (admin primero, luego operarios).
