# Caso de estudio para reclutadores - CoolImport PCP

## Resumen corto

Modernizacion de una app industrial en produccion desde MIT App Inventor hacia Flutter Android, manteniendo compatibilidad con backend Flask, Google Sheets, Supabase, Apps Script y API local de impresion. El objetivo fue mejorar mantenibilidad, UX y resiliencia sin detener operaciones en planta.

## Contexto

CoolImport S.A.C. opera procesos textiles donde la app movil participa en inventario, produccion, consulta de stock, despacho, QR e impresion. La version legacy en MIT App Inventor ya era usada por operarios reales, por lo que la migracion debia ser incremental y segura.

Datos relevantes:

| Area | Alcance |
|---|---|
| Sistema legacy | MIT App Inventor con multiples pantallas operativas |
| Backend | Flask en PythonAnywhere con endpoints existentes |
| Datos | Google Sheets, Supabase y Google Apps Script |
| Impresion | API local Flask para Zebra/Epson |
| Dispositivos | Tablets Android industriales administradas por MDM |
| Calidad | 61 tests automatizados y CI con GitHub Actions |

## Problema tecnico

La app original resolvia el negocio, pero tenia limitaciones para escalar:

- Interfaces dificiles de mantener y mejorar.
- Logica repartida en bloques visuales MIT.
- Manejo limitado de errores, carga, red e impresion.
- QR con formatos historicos distintos.
- Riesgo de romper operacion si se cambiaba backend o base de datos.

La solucion no podia ser una reescritura completa del ecosistema. La app Flutter debia convivir con MIT y consumir exactamente los mismos contratos.

## Mi enfoque

1. **Auditoria funcional:** identificar comportamiento real de pantallas MIT, endpoints, QR y formularios.
2. **Arquitectura Flutter por capas:** separar UI, providers, datasources, modelos, contratos y utilidades.
3. **Compatibilidad legacy:** centralizar rutas/payloads para no romper nombres esperados por Flask, Sheets o Apps Script.
4. **UX industrial:** convertir pantallas largas y confusas en flujos guiados con estados visibles.
5. **Offline first:** crear colas para operaciones donde no se puede perder informacion.
6. **Piloto seguro:** documentar runbooks, checklist GO/NO-GO, rollback y despliegue por anillos.

## Decisiones tecnicas destacables

### 1. Contratos legacy centralizados

Los endpoints y payloads se manejan desde una capa comun. Esto reduce riesgo cuando varios modulos dependen de nombres antiguos heredados de MIT App Inventor.

Archivo recomendado para revisar:

```text
lib/core/contracts/api_contracts.dart
```

### 2. Parsers QR defensivos

El sistema soporta QR de hilos, telas y formatos antiguos. Los parsers toleran campos faltantes, Kardex opcional y comas internas.

Archivos recomendados:

```text
lib/core/utils/qr_parser.dart
lib/core/utils/tela_qr_codec.dart
lib/core/utils/consulta_stock_qr_codec.dart
```

### 3. Colas offline para planta

Las operaciones criticas se guardan localmente cuando hay fallos de red o API local. Luego se reintentan sin perder el payload original.

Archivos recomendados:

```text
lib/data/models/*queue*.*
lib/presentation/providers/*queue*.*
```

### 4. UI enterprise para operarios

El redisenio prioriza lectura rapida, botones contextuales, estados de validacion y flujo paso a paso. El objetivo no fue solo hacerlo bonito, sino reducir errores operativos.

Areas recomendadas:

```text
lib/presentation/screens/auth/
lib/presentation/screens/almacen/
lib/presentation/screens/telas/
lib/presentation/widgets/
```

### 5. Seguridad de publicacion

El repositorio evita credenciales reales y usa inyeccion por `--dart-define` para builds controlados.

Archivos recomendados:

```text
SECURITY.md
docs/security_publish_checklist.md
```

## Impacto tecnico visible

- Migracion preparada para convivencia MIT + Flutter.
- Menor acoplamiento entre pantallas y backend.
- Validacion automatizada de contratos y parsers.
- Mejor tolerancia a red inestable.
- Mayor claridad visual para usuarios de planta.
- Documentacion suficiente para piloto, soporte y despliegue.

## Como evaluaria este proyecto en entrevista

Preguntas que este proyecto permite responder con evidencia:

- Como migrarias una app legacy productiva sin detener operaciones?
- Como mantienes compatibilidad con un backend que no puedes modificar?
- Como disenas UI para operarios que necesitan velocidad y baja confusion?
- Como manejas QR historicos con datos inconsistentes?
- Como evitas perdida de datos cuando falla la red o una API local?
- Como preparas un rollout controlado con rollback?

## Puntos fuertes para destacar

- No es un CRUD generico: es una app empresarial con restricciones reales.
- Incluye integracion con hardware/impresion local.
- Resuelve problemas de migracion, no solo UI.
- Tiene documentacion de arquitectura, seguridad, piloto y operacion.
- Usa pruebas automatizadas sobre los puntos que mas se rompen: parsers, contratos y colas.

## Limitaciones explicitas

- El backend productivo no esta incluido por seguridad.
- Las credenciales reales no se versionan.
- La validacion final depende de tablets, red de planta e impresoras reales.
- MIT App Inventor se mantiene como respaldo hasta cerrar piloto.

## Mensaje tecnico en una frase

Este proyecto muestra capacidad para modernizar software empresarial real con criterio de produccion: compatibilidad, resiliencia, seguridad, UX operativa y control de riesgo.
