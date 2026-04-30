# Runbook de piloto en planta - Flutter PCP

Actualizado: 2026-02-19

## 1) Preparacion tecnica (PC de desarrollo)

1. Abrir PowerShell en la raiz del proyecto.
2. Ejecutar preflight tecnico completo:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\preflight_pilot_check.ps1 -BuildApk
```

3. Revisar reporte generado en `docs/reports/preflight_latest.md`.
4. Confirmar que el reporte indique `GO PILOTO (preflight tecnico)`.

## 2) Build segura para produccion piloto

Para modulo de `Agregar proveedor` se recomienda inyectar credencial por variable de compilacion.

```powershell
flutter build apk --release --dart-define=GOOGLE_SHEETS_SA_B64=<BASE64_JSON>
```

Solo para contingencia controlada:

```powershell
flutter build apk --release --dart-define=ALLOW_EMBEDDED_SHEETS_CREDENTIALS=true
```

## 3) Despliegue por anillos (MDM Headwind)

- Anillo 1: 1-2 tablets de supervisores.
- Anillo 2: 4-6 tablets de operacion critica.
- Anillo 3: despliegue total.

En cada anillo validar en la app:

- `/telemetria_operativa`
- `/release_readiness`

## 4) Pruebas minimas por anillo

1. Login por rol (`ADMIN/PCP` y `OPERARIO`).
2. Flujo inventario (`Salida`, `Reingreso`, `Inventario Cero`).
3. Flujo produccion (`Urdido`, `Engomado`, `Telares`).
4. Flujo telas (`Gestion Stock`, `Ingreso Telas`, `Contenedor`).
5. `Agregar/Editar proveedor`.
6. Impresion local Zebra/Epson.
7. Corte de red de prueba y validacion de cola offline.

## 5) Criterio de pase

La salida a anillo siguiente requiere:

- Sin incidentes P1/P2 del anillo actual.
- Colas drenadas o bajo umbral operativo definido por PCP.
- `/release_readiness` en `GO PILOTO` al cierre de turno.

## 6) Rollback inmediato

Si ocurre incidente P1:

1. Publicar APK legacy por MDM.
2. Confirmar retorno operativo en tablets criticas.
3. Registrar incidente con modulo, hora y payload.
4. Congelar nueva version hasta cerrar causa raiz.
