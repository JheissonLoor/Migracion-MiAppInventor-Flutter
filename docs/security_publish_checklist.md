# Checklist de publicacion segura

Usar antes de subir cambios al repositorio publico.

## 1. Revisar estado Git

```bash
git status
git diff --cached --name-only
```

## 2. Buscar secretos comunes

```bash
git grep -n -I "BEGIN PRIVATE KEY\|private_key\|client_email\|ghp_\|github_pat_\|AIza\|AKIA\|Bearer " .
```

Solo deben aparecer plantillas o documentos de seguridad. Nunca valores reales.

## 3. Revisar rutas prohibidas

No deben aparecer en `git diff --cached --name-only`:

```text
temp/
build/
android/.gradle/
android/app/.cxx/
android/local.properties
assets/config/pcp_service_account.json
**/caramel-world-*.json
**/pruebacoolimportbusqueda-*.json
**/credentials/*.json
```

## 4. Validar app

```bash
flutter pub get
dart analyze
flutter test
```

## 5. Commit recomendado

```bash
git add .
git commit -m "docs: mejora documentacion publica del proyecto"
git push
```

## 6. Si se expone una credencial

1. Revocar la credencial en el proveedor.
2. Crear una credencial nueva.
3. Eliminar el archivo del repo.
4. Reescribir historial si ya fue publicado.
5. Verificar GitHub secret scanning.
6. Documentar el incidente y la correccion.
