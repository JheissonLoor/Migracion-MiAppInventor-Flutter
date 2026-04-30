# Decisiones de arquitectura

Este documento resume las decisiones tecnicas principales de la migracion MIT App Inventor a Flutter.

## ADR-001: Migracion incremental, no Big Bang

**Decision:** mantener MIT App Inventor operativo mientras Flutter alcanza paridad por modulos.

**Motivo:** el sistema esta en produccion y lo usan operarios reales. Un reemplazo total aumenta riesgo de parada, perdida de datos y errores de capacitacion.

**Consecuencia:** Flutter debe replicar contratos y comportamientos legacy antes de proponer mejoras internas.

## ADR-002: No modificar backend

**Decision:** conservar endpoints Flask, Google Sheets, Apps Script, Supabase y API local.

**Motivo:** el backend ya sostiene operacion diaria. Cambiarlo al mismo tiempo que la app multiplicaria el riesgo.

**Consecuencia:** se centralizan payloads legacy en `lib/core/contracts/api_contracts.dart` y se adaptan desde Flutter.

## ADR-003: Riverpod como estado principal

**Decision:** usar Riverpod/StateNotifier por modulo.

**Motivo:** permite estado testeable, bajo acoplamiento y separacion clara entre UI, reglas de pantalla y datasources.

**Consecuencia:** cada flujo critico tiene provider propio y estados explicitos de carga, exito, error y envio.

## ADR-004: Colas offline para operaciones criticas

**Decision:** persistir operaciones que no pueden perderse cuando falla red o API local.

**Motivo:** en planta puede caer WiFi, PythonAnywhere o API local de impresion. El operario no debe repetir datos ni perder movimientos.

**Consecuencia:** impresion, despacho, almacen y produccion tienen colas con telemetria de reintentos.

## ADR-005: Parsers QR tolerantes a legacy

**Decision:** aceptar 6, 8, 14, 16 y 19 campos segun flujo.

**Motivo:** existen QR antiguos, QR sin Kardex y datos con comas internas.

**Consecuencia:** el parser no asume CSV ideal; normaliza y conserva compatibilidad con MIT.

## ADR-006: Material 3 corporativo industrial

**Decision:** diseno enterprise claro, alto contraste, cards limpias y foco en operacion.

**Motivo:** la app se usa en tablets de planta. Debe verse seria y ser legible bajo presion operativa.

**Consecuencia:** se evita UI decorativa excesiva y se priorizan jerarquia, estados visibles y acciones grandes.

## ADR-007: Seguridad por defecto en repositorio publico

**Decision:** no versionar credenciales, dumps ni exports legacy sensibles.

**Motivo:** el proyecto usa Google Sheets, service accounts y backend productivo.

**Consecuencia:** `.gitignore`, `SECURITY.md` y checklist de publicacion son parte del baseline del repo.
