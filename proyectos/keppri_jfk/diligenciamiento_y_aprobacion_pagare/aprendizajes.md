# Proyecto: Diligenciamiento y Aprobación Pagaré

Bitácora de aprendizajes para el proyecto "Diligenciamiento y Aprobación Pagaré" de la empresa KEPPRI/JFK.

Documentación de Avances, Arquitectura y Lecciones Aprendidas

Proyecto: Automatización de Procesos RPA / QA — JFK Cooperativa Financiera
Proveedor / Equipo: Keppri
Ingeniero a cargo: Juan Alberto Ochoa Rivillas (Senior QA Automation Engineer)
Fecha de consolidación: Octubre 2026

1. Contexto del Proyecto y Estado Operativo

Se trabajó inicialmente en la fase de levantamiento de información (Discovery) y arquitectura técnica para la automatización del Proceso de Pagarés Inmaterializados de JFK Cooperativa Financiera, articulando la interacción entre la plataforma Web SMIC (JFK), Deceval y Google Drive.

Posteriormente, el cliente notificó la suspensión temporal de este proceso para dar paso a la socialización y levantamiento de un nuevo proceso operativo.

2. Decisiones Técnicas y de Arquitectura Tomadas

2.1 Infraestructura de Robots en UiPath Orchestrator

⚬ Capacidad del Robot: Se determinó que 1 solo Robot Unattended (Desatendido) es suficiente para procesar los 3 submódulos/procesos del flujo de pagarés. No se requieren 3 licencias separadas.
⚬ Manejo de Segregación de Funciones:
  ⚬ Regla de negocio: La persona que Diligencia no puede Aprobar, y quien Aprueba no puede Descargar Certificados.
  ⚬ Solución técnica: Una sola máquina/robot ejecuta los 3 procesos de forma secuencial o programada mediante Triggers, pero consume 3 Assets de Credenciales independientes en Orchestrator (Credenciales_Diligenciador, Credenciales_Aprobador, Credenciales_Descargador), cerrando e iniciando sesión entre etapas.

2.2 Patrón de Diseño y Framework

⚬ Framework: Robotic Enterprise Framework (REFramework) basado en Queues (Colas) de UiPath Orchestrator.
⚬ Patrón de Arquitectura: Dispatcher / Performer:
  ⚬ Dispatcher: Ingesta el archivo maestro Excel, filtra únicamente los registros con tipo de pagaré "Inmaterializado" y alimenta la cola de Orchestrator.
  ⚬ Performer: Consume las transacciones de la cola, realiza las operaciones UI/API y ejecuta los reintentos automáticos configurados ante fallas de sistema.

2.3 Sanitización y Manejo de Excepciones Tácticas

⚬ Sanitización de Identificadores (ID): Detección e implementación de limpieza de cadenas mediante Expresiones Regulares (Regex) para remover puntos (.) o espacios invisibles al final del N° de pagaré o cédula antes de consultar en Deceval.
⚬ Manejo de Bloqueos de Red en Deceval: Si durante la descarga de un certificado ocurre una caída de red, Deceval bloquea el pagaré por seguridad. El bot debe capturar la excepción de sistema, registrar la bandera "Requiere Desbloqueo Manual" en el archivo maestro y disparar un correo de alerta a la mesa de operaciones de JFK.

2.4 Integración con Servicios en la Nube

⚬ Google Drive API: Integración mediante UiPath Google Drive Integration Service (Service Account con credenciales JSON OAuth2) para la creación de carpetas y carga de certificados PDF sin interactuar con la interfaz web.

3. Estructura de Procesos y Diagramas Mermaid

Se crearon y refinaron los flujos de negocio (To-Be) para las 3 etapas principales del proceso suspendido:

Proceso 1: Diligenciamiento de Pagaré

graph TD
    A[Inicio: El Robot lee el archivo Excel de entrada] --> B{¿El pagaré dice 'Inmaterializado'?}
    B -- No --> C[Ignorar este registro y pasar al siguiente]
    B -- Sí --> D[Ingresar a la plataforma Deceval]
    
    D --> E[Consultar si el pagaré ya fue registrado antes]
    E --> F{¿El pagaré ya existe en Deceval?}
    F -- Sí --> G[Anotar en el Excel 'Ya Diligenciado' y continuar]
    F -- No --> H[Ingresar a la plataforma Web SMIC / JFK]
    
    H --> I[Buscar el crédito del cliente en Web SMIC]
    I --> J[Extraer datos del cliente: Tasa, Ciudad, Plan de pagos y Codeudores]
    J --> K[Ingresar al formulario de Deceval y llenar todos los datos]
    K --> L[Guardar en Deceval y obtener el Número de Pagaré generado]
    
    L --> M[Actualizar el Excel con el Número de Pagaré y marcar 'Diligenciado']
    M --> N[Fin: Enviar reporte de pagarés listos para Aprobación]


Proceso 2: Aprobación y Revisión de Pagaré

graph TD
    A[Inicio: El Robot recibe la lista de pagarés a revisar] --> B[Ingresar a Deceval a la sección de Aprobación]
    B --> C[Buscar el pagaré por su número]
    
    C --> D{¿Encontró el pagaré en Deceval?}
    D -- No --> E[Limpiar espacios o puntos al final del número y volver a buscar]
    E --> F
    D -- Sí --> F[Abrir el detalle del pagaré en Deceval]
    
    F --> G[Ingresar a Web SMIC y abrir el Plan de Pagos del cliente]
    G --> H[Comparar automáticamente: Datos de Deceval vs Datos de Web SMIC]
    
    H --> I{¿Todos los datos coinciden correctamente?}
    I -- No --> J[Escribir en Deceval qué datos quedaron mal y hacer clic en 'Rechazar']
    J --> K[Anotar 'Rechazado' en el Excel y enviar correo de alerta]
    
    I -- Sí --> L[Hacer clic en el botón 'Aprobar' en Deceval]
    L --> M[Anotar 'Aprobado' en el Excel y enviar correo de confirmación]
    
    K --> N[Fin Proceso 2]
    M --> N


Proceso 3: Descarga de Certificados y Entrega a Abogados

graph TD
    A[Inicio: El Robot toma los pagarés que ya fueron 'Aprobados'] --> B[Ingresar a Deceval a la sección 'Solicitar Certificados']
    B --> C[Buscar el número de pagaré]
    
    C --> D{¿Apareció el pagaré en pantalla?}
    D -- No --> E[Limpiar el número de pagaré y reintentar la búsqueda]
    E --> F
    D -- Sí --> F[Seleccionar el pagaré y solicitar la Certificación de Derechos Patrimoniales]
    
    F --> G[Hacer clic en 'Generar Certificado']
    G --> H{¿El sistema o el internet falló durante la descarga?}
    
    H -- Sí --> I[El pagaré queda bloqueado en Deceval por seguridad]
    I --> J[Marcar en el Excel 'Requiere Desbloqueo' y avisar por correo a Operaciones]
    
    H -- No --> K[Descargar el documento PDF]
    K --> L[Cambiar el nombre del archivo PDF poniéndole la Cédula del cliente]
    L --> M[Guardar el PDF en Google Drive en la carpeta del Abogado asignado]
    M --> N[Enviar un correo al Abogado con el certificado adjunto]
    
    J --> O[Fin Proceso 3]
    N --> O


4. Estructura del Documento de Levantamiento Operativo (Discovery)

Se consolidó el cuestionario de preguntas clave para el cliente en formato Word, con la siguiente tabla de contenido y referencias a los anexos PDF:

⚬ Documento base: KEPPRI — DOCUMENTO DE LEVANTAMIENTO OPERATIVO (Versión 1.0 — 2026)
⚬ Anexos adjuntos (Archivos PDF Versión Negocio):
  ⚬ P1-Diligenciamiento de Pagaré (Versión Negocio).pdf
  ⚬ P2-Aprobación y Revisión de Pagaré (Versión Negocio).pdf
  ⚬ P3-Descarga de Certificados y...bogados (Versión Negocio).pdf

Secciones del Cuestionario Consolidado:

1. Alcance General y Definiciones del Proyecto: Modelo de operación (100% automático vs. híbrido), confirmación de segregación de funciones, cuellos de botella actuales y rangos de montos.
2. Aspectos Generales y Accesos a Sistemas: Manejo y recepción del token OTP / Código T en Deceval, disponibilidad de entorno Sandbox/UAT, APIs/Web Services y formato de IDs (registros que inician con -).
3. Proceso 1 (Diligenciamiento): Procedimiento ante IDs no encontrados tras sanitización, descalce de datos SMIC vs. Deceval y ausencia de codeudores.
4. Proceso 2 (Aprobación): Mecanismo de notificación entre etapas y reprocesamiento de pagarés rechazados.
5. Proceso 3 (Descarga y Entrega): Tiempos y flujo de desbloqueo de pagarés, ubicación del archivo maestro (Excel local vs. Google Sheets) y estructura de carpetas/correos a abogados.
6. Volumetría y Tiempos: Cantidad de personas involucradas, cantidad de pagarés procesados por día y tiempos de ejecución individual vs. grupal.

5. Requerimientos Técnicos para la Solicitud de Ambiente UiPath

Para la habilitación de la infraestructura de desarrollo se definió el siguiente pliego técnico:

⚬ Licenciamiento: 1 Licencia UiPath Studio Pro + 1 Robot Unattended en Orchestrator (Folder Dev/QA).
⚬ Máquina Virtual (VM Dev): Windows 10/11 Pro, 16 GB RAM, 4 vCPU, permisos de Administrador local.
⚬ Navegador: Chrome / Edge con extensión UiPath Web Automation habilitada.
⚬ Credenciales y Accesos:
  ⚬ 2 cuentas de pruebas en Deceval Sandbox (1 Diligenciador, 1 Aprobador) + habilitación/bypass de OTP para el bot.
  ⚬ Credenciales de pruebas en Web SMIC (JFK QA).
  ⚬ Whitelist de IP de la VM en Deceval si aplica.
⚬ Google Cloud: Service Account con API de Google Drive activa + permisos de edición en la carpeta contenedora.
⚬ Azure DevOps: Permisos en Repos (Git) y Test Plans / Boards.

6. Checklist de Transición hacia el Nuevo Proceso

Ante la suspensión del proceso de pagarés y la llegada de una nueva iniciativa, se estableció el siguiente checklist operacional de 6 pasos:

1. Definición del Nuevo Proceso: Nombre, objetivo principal del área operativa, sistemas involucrados (Web, Escritorio, Excel) y archivos de entrada/salida.
2. Flujo Operativo y Reglas: Mapeo del paso a paso (Happy Path), criterios de decisión/aprobación y verificación de segregación de roles.
3. Excepciones y Casos Especiales: Protocolo ante datos errados/incompletos, fallas de plataforma y canales/formatos de notificación de rechazos.
4. Aspectos Técnicos y Seguridad: Requisitos de VPN, OTP/MFA, Captcha, disponibilidad de entorno QA/UAT y ubicación física o en nube de los insumos (OneDrive, Drive, Red).
5. Volumetría y Operación: Cantidad de registros diarios/mensuales, tiempos actuales de ejecución humana (individual y lote) y ventanas operativas/mantenimientos.
6. Cierre de Sesión: Emisión de minuta de acuerdos y diseño del diagrama funcional preliminar para validación.
