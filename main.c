/* main.c - Programa principal del traductor Pascal a Python */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

extern int yyparse();
extern FILE* yyin;
extern int yylineno;

FILE* output_file = NULL;  // Definición de la variable global

void print_usage(const char* program_name) {
    printf("Uso: %s <archivo_pascal> [archivo_salida]\n", program_name);
    printf("  archivo_pascal: Archivo fuente Pascal (.pas)\n");
    printf("  archivo_salida: Archivo Python de salida (opcional, default: salida.py)\n");
}

int main(int argc, char* argv[]) {
    char* input_filename = NULL;
    char* output_filename = "salida.py";
    
    // Verificar argumentos
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }
    
    input_filename = argv[1];
    
    if (argc >= 3) {
        output_filename = argv[2];
    }
    
    // Abrir archivo de entrada
    yyin = fopen(input_filename, "r");
    if (!yyin) {
        fprintf(stderr, "Error: No se puede abrir el archivo '%s'\n", input_filename);
        return 1;
    }
    
    // Abrir archivo de salida
    output_file = fopen(output_filename, "w");
    if (!output_file) {
        fprintf(stderr, "Error: No se puede crear el archivo '%s'\n", output_filename);
        fclose(yyin);
        return 1;
    }
    
    printf("Traduciendo '%s' a '%s'...\n", input_filename, output_filename);
    
    // Analizar el archivo
    if (yyparse() == 0) {
        printf("Traducción completada exitosamente.\n");
    } else {
        printf("Error durante la traducción.\n");
        fclose(yyin);
        fclose(output_file);
        return 1;
    }
    
    // Cerrar archivos
    fclose(yyin);
    fclose(output_file);
    
    return 0;
}