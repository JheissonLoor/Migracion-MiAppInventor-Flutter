# Guia de revision para evaluadores tecnicos

Este repositorio esta pensado como evidencia de una migracion real de sistema legacy a Flutter. Si estas revisando el proyecto por perfil tecnico, estas son las zonas mas relevantes.

## Revision rapida en 10 minutos

1. Leer `README.md` para contexto de negocio y alcance.
2. Leer `docs/recruiter_case_study.md` para entender decisiones e impacto.
3. Revisar `lib/core/contracts/api_contracts.dart` para entender compatibilidad legacy.
4. Revisar `lib/core/utils/` para parsers QR y tolerancia a datos reales.
5. Revisar `lib/data/models/*queue*` para estrategia offline.
6. Revisar `lib/presentation/screens/auth/login_screen.dart` y widgets de login para UI corporativa.
7. Revisar `docs/mit_flutter_gap_audit_2026-04-28.md` para paridad MIT vs Flutter.
8. Revisar tests en `test/core` y `test/data`.

## Que deberia observarse

- Separacion entre UI, providers, datasources y modelos.
- Contratos legacy centralizados para evitar typos.
- Manejo explicito de estados de carga/error/envio.
- Parsers QR con casos de datos no ideales.
- Colas offline en operaciones criticas.
- Documentacion de piloto, rollback y despliegue.

## Preguntas tecnicas que el proyecto responde

- Como migrar una app MIT App Inventor productiva sin detener operacion.
- Como consumir un backend legacy sin cambiar sus endpoints.
- Como manejar datos con formatos QR historicos.
- Como operar con red inestable en planta.
- Como preparar una app Flutter para tablets industriales.
- Como controlar riesgos antes de un piloto real.

## Evidencias de calidad

```bash
flutter pub get
dart analyze
flutter test
```

Tambien existe CI en GitHub Actions para validar cada push y pull request. La suite actual mantiene 61 tests automatizados orientados a contratos legacy, parsers QR, modelos y bootstrap de app.

## Limites intencionales

- No se incluye backend productivo.
- No se incluyen credenciales reales.
- No se incluyen exports AIA con secretos.
- No se alteran contratos legacy.
- La validacion final requiere tablets y red real de planta.
