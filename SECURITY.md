# Seguridad y manejo de secretos

Este repositorio no debe contener credenciales reales, service accounts, tokens, `.env`, keystores ni dumps de sistemas productivos.

## Politica de secretos

- No versionar `assets/config/pcp_service_account.json`.
- No versionar archivos `.env`, `.pem`, `.p12`, `.jks`, `.keystore`.
- No versionar exportaciones `.aia` o carpetas temporales con assets legacy si contienen credenciales.
- Usar `--dart-define=GOOGLE_SHEETS_SA_B64=<BASE64_JSON>` para builds controlados.
- Rotar inmediatamente cualquier credencial que haya sido expuesta.

## Antes de hacer push

Ejecutar:

```bash
flutter test
dart analyze
rg -n --hidden --glob '!build/**' --glob '!.dart_tool/**' --glob '!.git/**' \
  "(BEGIN PRIVATE KEY|private_key|client_email|api_key|ghp_|github_pat_|AIza|AKIA|Bearer )" .
```

Los archivos `*.example.*` pueden contener placeholders, pero nunca valores reales.

## Reporte

Si encuentras un secreto expuesto, no abras un issue publico con el valor. Revoca la credencial y limpia el historial antes de publicar.
