# Perfil profesional CoolImport - Experiencia tecnica ampliada

Este documento consolida la experiencia tecnica desarrollada alrededor del ecosistema CoolImport. No se limita a la app movil: incluye aplicaciones de escritorio, APIs locales, integraciones con Google Sheets, automatizacion documental, soporte operativo, impresion industrial y despliegue en tablets.

## Resumen ejecutivo

Rol recomendado para CV/LinkedIn:

```text
Practicante de TI / Desarrollador de Software Empresarial
CoolImport S.A.C. | Lima, Peru
Modernizacion de sistemas internos, integracion de APIs, automatizacion de procesos textiles, soporte tecnico e implementacion de soluciones moviles y de escritorio para operacion real en planta.
```

Propuesta de descripcion corta:

```text
Desarrollo y modernizacion de soluciones internas para inventario, produccion, despacho, facturacion e impresion industrial. Trabajo con Flutter, Python, Flask, Google Sheets API, Supabase, Apps Script, Excel, QR, impresoras Zebra/Epson y tablets Android gestionadas por MDM, manteniendo compatibilidad con sistemas legacy en produccion.
```

## Alcance real de responsabilidades

| Area | Evidencia tecnica |
|---|---|
| Aplicaciones moviles | Migracion de MIT App Inventor a Flutter para inventario, produccion, stock, QR y despacho |
| APIs REST | Flask en nube y API local para impresion, PDF, QR, despacho y sincronizacion con Sheets |
| Bases de datos hibridas | Google Sheets operacional, Supabase, Excel local y Apps Script |
| Automatizacion documental | Extraccion masiva de XML UBL/SUNAT a Excel y registro de facturas |
| Impresion industrial | Zebra para etiquetas QR y Epson para documentos de despacho |
| MDM / tablets | Preparacion de APK, despliegue por anillos, pruebas en tablets Android industriales |
| Soporte TI | Red local, IP fija, impresoras, dependencias Python, usuarios y continuidad operativa |
| UX empresarial | Interfaces mas claras para operarios, formularios guiados y validaciones inline |

---

## Proyecto 1: App movil PCP - Flutter industrial

Modernizacion de una app legacy usada en planta para procesos de inventario y produccion.

### Tecnologias

- Flutter / Dart
- Material 3
- Riverpod / StateNotifier
- Dio
- QR scanner / QR generator
- Google Sheets, Supabase, Flask, Apps Script
- Colas offline y telemetria operativa
- GitHub Actions

### Logros destacables

- Migracion incremental desde MIT App Inventor sin detener operaciones.
- Compatibilidad con endpoints legacy y payloads existentes.
- Parsers QR para formatos de 6, 8, 14, 16 y 19 campos.
- Normalizacion de QR con Kardex opcional, comas internas y codigos incompletos.
- Colas offline para despacho, impresion, salida/reingreso, produccion y proveedores.
- Pantallas corporativas para tablets Android industriales.
- Checklist GO/NO-GO, runbook de piloto y estrategia de despliegue por anillos MDM.
- 61 tests automatizados para parsers, contratos, modelos y bootstrap.

### Frase de impacto

```text
Converti una app legacy de planta en una solucion Flutter empresarial, manteniendo compatibilidad operacional y agregando resiliencia offline, UI corporativa y validacion automatizada.
```

---

## Proyecto 2: API local Tela Cruda - Impresion, QR y despacho

Servicio Flask ejecutado en Windows dentro de la red local para conectar la app movil con impresoras fisicas y Google Sheets.

### Tecnologias

- Python / Flask
- Flask-CORS
- FPDF y ReportLab
- Google Sheets API / gspread / oauth2client
- Impresoras Zebra y Epson
- Windows printto / WMIC
- QR en PDF

### Funcionalidades identificadas

- `GET /health`: verificacion de estado, IP, puerto, impresoras y Google Sheets.
- `GET /impresoras`: listado de impresoras instaladas y validacion de Zebra/Epson.
- `GET /test_sheets`: prueba de conexion con hojas operativas.
- `POST /generate_pdf`: generacion de etiqueta QR para Zebra.
- `POST /imprimir`: envio de etiqueta PDF a Zebra.
- `POST /imprimir_despacho`: generacion de PDF de despacho, impresion Epson y registro en Sheets.
- Registro en hojas de despacho y detalle.
- Actualizacion de stock para marcar rollos despachados.
- Generacion de correlativos secuenciales de despacho.
- Manejo de payloads provenientes de MIT/App Flutter.

### Valor tecnico

```text
Integre software movil con hardware de planta mediante una API local Flask, resolviendo impresion fisica, generacion de PDF, trazabilidad de despachos y sincronizacion con Google Sheets.
```

---

## Proyecto 3: APP amigable - Registro de facturas con Google Sheets y Excel

Aplicacion de escritorio para registro operativo de facturas de importacion, pensada para usuarios no tecnicos.

### Tecnologias

- Python
- Tkinter
- openpyxl
- gspread
- Google Auth / Service Account
- JSON config local
- Excel como fallback

### Funcionalidades identificadas

- Formulario completo en secciones: proveedor, comprobante y producto.
- Calculo automatico de IGV, subtotal y total.
- Validacion de datos con mensajes claros.
- Guardado en Google Sheets mediante Service Account.
- Fallback a Excel local cuando no hay conexion.
- Historial local de facturas.
- Wizard de configuracion de Google Sheets en pasos guiados.
- Compartir hoja con encargada por correo.
- Verificacion periodica de conexion con Google Sheets.
- Configuracion local portable en JSON.
- Estilos personalizados, alto contraste y soporte DPI en Windows.
- Instaladores `.bat` para usuarios finales.

### Valor tecnico

```text
Desarrolle una app de escritorio para usuarios administrativos, con sincronizacion cloud, respaldo local y configuracion guiada, reduciendo dependencia de procesos manuales en Excel.
```

---

## Proyecto 4: Extractor de facturas XML - SUNAT UBL 2.1 a Excel

Herramienta de escritorio para procesar facturas electronicas peruanas en XML y convertirlas a reportes Excel estructurados.

### Tecnologias

- Python
- XML ElementTree
- Tkinter / ttk
- openpyxl
- Threading para no bloquear UI
- Procesamiento masivo de carpetas

### Funcionalidades identificadas

- Parser de XML UBL 2.1 / SUNAT.
- Extraccion de numero de factura, fecha, RUC, cliente, guia, moneda, items, cantidades, precios, importes y total.
- Procesamiento de carpetas y subcarpetas.
- Barra de progreso y estado por archivo.
- Exportacion a Excel con formato profesional.
- Congelado de encabezados, autoajuste, zebra rows y formatos numericos.
- Manejo de XML invalidos con lista de errores.
- Carpeta local con mas de 1,100 XML detectados para procesamiento masivo.

### Valor tecnico

```text
Automatice la lectura masiva de facturas electronicas SUNAT y la conversion a Excel operativo, reduciendo trabajo manual y errores de digitacion.
```

---

## Version LinkedIn - Experiencia completa

```text
Practicante de TI / Desarrollador de Software Empresarial
CoolImport S.A.C. | Lima, Peru

Desarrollo, modernizacion y soporte de sistemas internos para una empresa textil, participando en soluciones moviles, APIs, automatizacion documental, integraciones con Google Sheets/Supabase y soporte operativo en planta.

Principales responsabilidades y logros:

- Migracion de app legacy en MIT App Inventor hacia Flutter Android para inventario, produccion, stock, QR, despacho e impresion.
- Desarrollo de arquitectura Flutter por capas, con providers, datasources, modelos, contratos legacy, parsers QR y colas offline.
- Integracion con backend Flask/PythonAnywhere, Supabase, Google Sheets y Google Apps Script, manteniendo compatibilidad con endpoints productivos.
- Desarrollo y mantenimiento de API local Flask para generar PDF, etiquetas QR, despachos e imprimir en Zebra/Epson dentro de red de planta.
- Administracion de datos operativos en Google Sheets, Supabase y Excel, incluyendo validacion, sincronizacion y control de registros.
- Automatizacion de facturas electronicas XML SUNAT hacia Excel mediante Python, procesamiento masivo de archivos y reportes estructurados.
- Desarrollo de aplicacion de escritorio para registro de facturas con Tkinter, Google Sheets API, Excel fallback, validaciones y configuracion guiada.
- Preparacion de APKs, pruebas en tablets Android industriales y soporte para despliegue mediante MDM.
- Soporte tecnico a usuarios internos, impresoras, red local, dependencias Python, APIs, tablets y continuidad operativa.
- Documentacion tecnica, checklist de piloto, estrategia de rollback y control de seguridad para evitar exposicion de credenciales.

Stack: Flutter, Dart, Python, Flask, Tkinter, Google Sheets API, Supabase, Apps Script, Excel/openpyxl, QR, REST APIs, Zebra/Epson, Android, MDM, Git/GitHub.
```

---

## Version CV ATS - Bullet points fuertes

```text
- Modernice una aplicacion movil legacy de MIT App Inventor a Flutter Android para procesos textiles de inventario, produccion, stock, QR y despacho.
- Dise?e una arquitectura Flutter por capas con UI, estado, datasources, modelos, contratos legacy, parsers QR y colas offline.
- Integre la app con Flask, PythonAnywhere, Google Sheets, Supabase, Apps Script y una API local de impresion sin romper contratos productivos.
- Desarrolle y mantuve una API local Flask para generar PDF, etiquetas QR, despachos e imprimir en Zebra y Epson dentro de red de planta.
- Implemente parsers robustos para QR legacy de 6, 8, 14, 16 y 19 campos, tolerando Kardex opcional, comas internas y codigos incompletos.
- Automatice el procesamiento de facturas electronicas SUNAT XML UBL 2.1 hacia Excel, con extraccion de datos de cabecera e items.
- Cree una aplicacion de escritorio en Python/Tkinter para registro de facturas con calculo automatico de IGV, Google Sheets API y respaldo Excel local.
- Administre datos operativos en Google Sheets, Supabase y Excel, aplicando validaciones, sincronizacion y fallback ante fallos de red.
- Prepare APKs, pruebas en tablets Android industriales y estrategia de despliegue controlado mediante MDM.
- Brinde soporte tecnico a usuarios, impresoras, red local, APIs, dependencias Python y continuidad de operaciones en planta.
```

---

## Version corta para cabecera de portafolio

```text
Desarrollador de software orientado a sistemas empresariales industriales. He trabajado en la modernizacion de una app productiva de MIT App Inventor a Flutter, integrando Flask, Google Sheets, Supabase, APIs locales, QR, impresion Zebra/Epson, automatizacion de facturas XML y soporte operativo para tablets Android en planta.
```

---

## Prompt para IA que construira tu portafolio

```text
Actua como dise?ador senior de portafolios tech, copywriter para recruiters y arquitecto de informacion.

Quiero crear una seccion de portafolio profesional para mi experiencia en CoolImport S.A.C. No quiero que parezca una lista basica de tareas; quiero que se vea como experiencia real de software empresarial en produccion.

Contexto:
Soy practicante de Ingenieria de Sistemas y he trabajado en modernizacion de sistemas internos para una empresa textil peruana. Mi trabajo incluye desarrollo movil, APIs, automatizacion, integraciones con Google Sheets/Supabase, soporte tecnico e impresion industrial.

Proyectos que debes incluir:

1. App movil PCP:
- Migracion de MIT App Inventor a Flutter Android.
- Inventario, produccion, stock, QR, despacho e impresion.
- Backend Flask/PythonAnywhere sin cambiar endpoints.
- Google Sheets, Supabase, Apps Script.
- Parsers QR para 6, 8, 14, 16 y 19 campos.
- Colas offline, telemetria, Material 3, tablets Android industriales y MDM.
- GitHub Actions y 61 tests automatizados.

2. API local Tela Cruda:
- Python Flask en Windows dentro de red local.
- Endpoints /health, /impresoras, /test_sheets, /generate_pdf, /imprimir, /imprimir_despacho.
- Generacion de PDF, QR, etiquetas Zebra, documentos Epson, registro en Google Sheets y actualizacion de stock.

3. APP amigable de facturas:
- App escritorio Python/Tkinter.
- Registro de facturas de importacion.
- Calculo automatico de IGV, subtotal y total.
- Validaciones amigables.
- Google Sheets API con Service Account.
- Excel local como fallback offline.
- Wizard de configuracion para usuarios no tecnicos.

4. Extractor de facturas XML:
- Procesamiento de facturas electronicas peruanas XML UBL 2.1/SUNAT.
- Extraccion de datos a Excel: factura, fecha, RUC, cliente, guia, moneda, items, cantidades, precios, importes y total.
- Procesamiento masivo de carpetas, barra de progreso y Excel formateado.

Tambien destacar:
- Soporte tecnico a usuarios, tablets, red local, impresoras y dependencias Python.
- Administracion de datos en Google Sheets, Supabase y Excel.
- Seguridad: no exponer credenciales, uso de plantillas y configuracion controlada.
- Despliegue y pruebas con APKs/tablets/MDM.

Entrega:
- Hero del portafolio.
- Seccion de experiencia profesional.
- 4 project cards con problema, solucion, stack e impacto.
- Timeline tecnico.
- Texto para reclutadores.
- Bullets para CV ATS.
- Tono profesional, moderno, claro y empresarial.
```

---

## Post LinkedIn completo

```text
Durante mi experiencia en CoolImport S.A.C. he estado trabajando en algo que va mas alla de una app: la modernizacion de un ecosistema interno usado en operacion real.

El reto principal fue trabajar con sistemas que ya estaban en produccion, usados por operarios y personal administrativo, sin detener procesos ni romper integraciones existentes.

Algunas soluciones en las que he trabajado:

- Migracion de una app legacy en MIT App Inventor hacia Flutter Android para inventario, produccion, stock, QR, despacho e impresion.
- Integracion con Flask/PythonAnywhere, Google Sheets, Supabase y Google Apps Script.
- Desarrollo de una API local Flask para generar PDF, etiquetas QR, despachos e imprimir en Zebra/Epson dentro de red de planta.
- Implementacion de parsers QR para formatos legacy de 6, 8, 14, 16 y 19 campos.
- Colas offline para operaciones criticas cuando falla la red o la API local.
- App de escritorio en Python/Tkinter para registrar facturas con Google Sheets API y respaldo Excel.
- Automatizacion de facturas electronicas XML SUNAT hacia Excel, con procesamiento masivo y reportes formateados.
- Pruebas en tablets Android industriales, preparacion de APKs y despliegue controlado mediante MDM.
- Soporte tecnico a usuarios, impresoras, red local, APIs y continuidad operativa.

Este proceso me ense?o que en software empresarial no basta con que el codigo funcione. Tambien debe respetar la operacion real, convivir con sistemas legacy, manejar errores, proteger datos y ser entendible para usuarios no tecnicos.

Stack: Flutter, Dart, Python, Flask, Tkinter, Google Sheets API, Supabase, Apps Script, Excel/openpyxl, REST APIs, QR, Zebra/Epson, Android, Git/GitHub.

#Flutter #Python #SoftwareEngineering #LegacyMigration #APIs #GoogleSheets #Supabase #IndustrialSoftware #Automation #Android
```

---

## Titulares recomendados para LinkedIn

```text
Practicante de TI | Flutter & Python | Migracion Legacy | APIs REST | Google Sheets/Supabase | Automatizacion Industrial
```

```text
Desarrollador Flutter/Python orientado a sistemas empresariales, APIs, automatizacion e integraciones industriales
```

```text
Ingenieria de Sistemas | Flutter Android | Python Flask | Google Sheets API | Software para operaciones industriales
```

---

## Tecnologias para mostrar en el portafolio

```text
Flutter, Dart, Python, Flask, Tkinter, REST APIs, Google Sheets API, Supabase, Google Apps Script, Excel/openpyxl, XML UBL 2.1, QR, PDF, Zebra, Epson, Android, MDM, Git, GitHub Actions, Windows, soporte tecnico, automatizacion de procesos.
```

---

## Criterio de comunicacion

Cuando lo pongas en portafolio o LinkedIn, evita decir solo:

```text
Hice una app movil y soporte tecnico.
```

Mejor decir:

```text
Modernice e integre soluciones internas para una operacion textil real, conectando app movil, APIs, Google Sheets, Supabase, automatizacion documental, impresion industrial y soporte en planta bajo restricciones de continuidad operativa.
```
