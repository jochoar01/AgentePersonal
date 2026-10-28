# Proyecto: Proceso de Consulta Patrimonial
Documentación Técnica: Automatización Cartera Jurídica (JFK Cooperativa Financiera)

1. Contexto del Proyecto y Línea Base Operativa

⚬ Proyecto: Automatización del Proceso de Consulta Patrimonial / Cartera Jurídica.
⚬ Organización: JFK Cooperativa Financiera.
⚬ Universo de Cartera: 19,000 clientes totales.
⚬ Volumetría Objetivo (Lote Mensual): 300 a 400 clientes por ciclo.
⚬ Esfuerzo Humano Actual: 15 personas dedicando 1 día completo al mes de forma manual para la ejecución de las consultas.
⚬ Destino de Resultados: Segmentación de resultados positivos hacia abogados para iniciar demandas, y negativos hacia una empresa de cobranza externa.

2. Alcance, Fuentes Oficiales y Exclusiones

⚬ Fuentes de Consulta Incluidas (Automatización Web / Scraping):
  1. Registraduría: Validación de vigencia y estado de fallecido (descartando fallecidos extranjeros por complejidad documental con aseguradoras).
  2. ADRES: Estado de afiliación, tiempo inactivo o condición de beneficiario.
  3. RUES: Verificación de establecimientos de comercio activos a nombre del cliente.
  4. Supernotariado: Consulta de bienes inmuebles a embargar (implementando Credential Pooling para sortear la restricción de 11 consultas por sesión).
  5. SIMIT: Consulta de multas e infracciones vigentes.
  6. RUNT: Validación vehicular mediante consulta por placa para confirmar titularidad de bienes muebles.
⚬ Fuentes Excluidas Explícitamente:
  ⚬ RUAF: Excluido del alcance automatizado por requerir datos adicionales como la fecha exacta de expedición del documento de identidad.

3. Decisiones Técnicas y Arquitectura

⚬ Procesamiento en Memoria: Uso optimizado de DataTables para procesar el lote en memoria y evitar escrituras/lecturas constantes en disco durante la iteración del lote.
⚬ Gestión de Credenciales Sensibles: Uso de Credential Pooling administrado mediante UiPath Orchestrator Assets para la rotación transparente de cuentas en el portal de Supernotariado.
⚬ Compatibilidad de Documentación: Estandarización de los textos operativos utilizando numeración simple (1., 2., 3.) y viñetas de texto plano (-) para evitar que el portapapeles corrompa el formato al pegarlo en Word Online.

4. Artefactos y Código Escrito

Diagrama de Flujo Funcional (Mermaid JS)

flowchart TD
    %% Definición de Estilos
    classDef inicio fill:#d4edda,stroke:#28a745,stroke-width:2px,color:#155724;
    classDef proceso fill:#cce5ff,stroke:#004085,stroke-width:2px,color:#004085;
    classDef decisiones fill:#fff3cd,stroke:#856404,stroke-width:2px,color:#856404;
    classDef fin fill:#e2e3e5,stroke:#383d41,stroke-width:2px,color:#383d41;

    subgraph Fase1 [1. Inicialización y Entrada]
        A[Inicio: Plantilla Base Estandarizada] --> B[Cargar 300-400 Clientes en DataTable]
        B --> C[For Each Cliente]
    end

    subgraph Fase2 [2. Bloque de Consultas - Fuentes Oficiales]
        C --> D1[1. Registraduría: Vigencia / Fallecido]
        D1 --> D2[2. ADRES: Empleo / Inactivo]
        D2 --> D3[3. RUES: Establecimientos]
        D3 --> D4[4. Supernotariado: Inmuebles - Credential Pooling]
        D4 --> D5[5. SIMIT: Multas]
        D5 --> D6[6. RUNT: Validación por Placa]
    end

    subgraph Fase3 [3. Consolidación y Salida]
        D6 --> E[Consolidar Resultados en Matriz]
        E --> F{¿Fin de Lote?}
        F -->|No| C
        F -->|Sí| G[Escritura Única Archivo Final]
        G --> H[Entrega: Abogados y Cobranza]
        H --> I[Fin del Proceso]
    end

    %% Aplicación de Clases
    class A,B inicio;
    class C,D1,D2,D3,D4,D5,D6,E,G proceso;
    class F decisiones;
    class H,I fin;


Comandos de Consola para macOS (Estructura de Directorios)

Comando limpio para listar la estructura de archivos del proyecto excluyendo entornos virtuales (venv) y archivos ocultos del sistema:

find . -not -path '*/.*' -not -path '*/venv*' | sort


5. Estructura del Documento de Levantamiento Operativo

El documento oficial estructurado para este proyecto se compone de los siguientes apartados:

1. Contexto y Validación de Diagramas Funcionales (Referencia al diagrama en PNG).
2. Alcance General y Definiciones del Proyecto
  ⚬ Origen del Archivo Base / Extracción Inicial
  ⚬ Modelo y Frecuencia de Ejecución
  ⚬ Delimitación del Alcance y Filtros de Datos
  ⚬ Arquitectura de Datos y Entrega
  ⚬ Origen de los Datos y Conectividad (Fuentes Oficiales y Exclusiones)
3. Cuestionario de Levantamiento de Información
  ⚬ 3.1 Aspectos Generales y Accesos a Sistemas (CAPTCHAs y Credential Pooling)
  ⚬ 3.2 Proceso 1: Carga, Validación y Barrido en Lote (Sanitización y Manejo de Inconsistencias)
  ⚬ 3.3 Proceso 2: Control de Excepciones, SIMIT y RUNT (Caídas de portales y validación vehicular)
  ⚬ 3.4 Proceso 3: Consolidación, Escritura Única y Entrega (DataTables en memoria y canales de entrega)
  ⚬ 3.5 Operación, Tiempos y Volumetría (Recurso humano, lotes y tiempos por registro individual)
Bitácora de aprendizajes para el proyecto "Proceso de Consulta Patrimonial" de la empresa KEPPRI/JFK.
