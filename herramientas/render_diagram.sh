#!/bin/bash

# Script para renderizar diagramas Mermaid a PNG
# Uso: ./render_diagram.sh <archivo_entrada.mmd> <archivo_salida.png>

if ! command -v mmdc &> /dev/null; then
    echo "Error: mmdc (mermaid-cli) no está instalado."
    echo "Instálalo primero con: npm install -g @mermaid-js/mermaid-cli"
    exit 1
fi

if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <archivo_entrada.mmd> <archivo_salida.png>"
    exit 1
fi

mmdc -i "$1" -o "$2"
echo "Diagrama renderizado en: $2"
