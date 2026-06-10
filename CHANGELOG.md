# Changelog

Todos los cambios relevantes del proyecto se documentan aqui.

El formato sigue una variante simple de Keep a Changelog y los commits usan mensajes en espanol con prefijo convencional.

## [Unreleased]

### Agregado

- README redisenado como caso de estudio tecnico para portafolio.
- Caso de estudio para reclutadores en `docs/recruiter_case_study.md`.
- Perfil profesional ampliado del ecosistema CoolImport en `docs/coolimport_professional_profile.md`.
- Guia de revision tecnica actualizada para evaluadores.

### Corregido

- Gestion Stock Telas normaliza codigos QR nuevos incompletos (`T20F040626-1-`) cuando existe correlativo.
- API local de impresion actualizada a la IP productiva reciente con fallback legado.

### Pendiente

- Validar piloto final en tablets reales dentro de red de planta.
- Ejecutar prueba de impresion Zebra/Epson con API local productiva.
- Documentar resultados del rollout por anillos MDM.
- Reducir infos de analyzer como deuda tecnica planificada.

## [2.0.0] - 2026-04-30

### Agregado

- Migracion Flutter con arquitectura por capas.
- Login corporativo responsive con Material 3.
- Home Admin y Operario con lenguaje visual enterprise.
- Consulta Stock PCP con parser QR legacy.
- Salida y reingreso de almacen.
- Cambio de almacen y cambio de ubicacion.
- Inventario cero.
- Gestion Stock Telas e Ingreso Telas.
- Impresion de etiquetas con API local, QR y cola offline.
- Generacion de Kardex compatible con backend legacy.
- Modulos de produccion: Urdido, Engomado, Telares e Ingreso Telar.
- Historiales operativos y administrativos.
- Administracion de usuarios y proveedores.
- Telemetria operativa de colas.
- Release readiness para piloto.
- GitHub Actions para analisis estatico y tests.

### Seguridad

- Repositorio publico saneado.
- Credenciales reales excluidas por `.gitignore`.
- Plantilla de service account sin secretos reales.
- Checklist de publicacion segura.

### Validado

 - `flutter test`: 61 tests en verde.
- `dart analyze`: sin errores.
- CI remoto en GitHub Actions en verde.
