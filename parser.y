/* parser.y - Analizador sintáctico mejorado para Pascal */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern FILE* yyin;
extern FILE* output_file;
extern int yylineno;

int line_num = 1;
int indent_level = 0;
char current_function[256] = "";
int label_counter = 0;
int if_counter = 0;

void yyerror(const char* msg);
void generate_indent();
void generate_python_header();
void generate_python_footer();
char* generate_label();
char* get_default_value(const char* type);
void process_variable_list_for_declaration(char* var_list, char* type_str);
%}

%union {
    int num;
    double real;
    char* str;
}

/* Tokens */
%token PROGRAM USES VAR T_BEGIN END IF THEN ELSE WHILE DO FOR TO REPEAT UNTIL
%token PROCEDURE FUNCTION INTEGER_TYPE REAL_TYPE BOOLEAN_TYPE STRING_TYPE
%token TRUE_VAL FALSE_VAL AND OR NOT DIV MOD
%token WRITELN WRITE READLN READ CLRSCR
%token ASSIGN EQUAL NOT_EQUAL LESS_EQUAL GREATER_EQUAL LESS GREATER
%token PLUS MINUS MULTIPLY DIVIDE
%token LPAREN RPAREN SEMICOLON COLON DOT COMMA

%token ARRAY OF RECORD SET POINTER CASE GOTO LABEL CONST FILE_TYPE TEXT_TYPE WITH IN
%token OBJECT CLASS CONSTRUCTOR DESTRUCTOR INHERITED PRIVATE PROTECTED PUBLIC
%token TRY EXCEPT FINALLY RAISE
%token RANGE_DOTS
%token POINTER_DEREF
%token ADDRESS_OF

%token <str> IDENTIFIER STRING_VAL
%token <num> NUMBER
%token <real> REAL_NUM

%type <str> constant_value
%type <str> case_expression
%type <str> type
%type <str> identifier_list    /* AGREGAR ESTA LÍNEA */

/* Precedencia y asociatividad */
%right ASSIGN
%left OR
%left AND
%right NOT
%left EQUAL NOT_EQUAL LESS GREATER LESS_EQUAL GREATER_EQUAL
%left PLUS MINUS
%left MULTIPLY DIVIDE DIV MOD
%right UMINUS

%start program

%%

program:
    PROGRAM IDENTIFIER SEMICOLON
    {
        generate_python_header();
        fprintf(output_file, "# Traducido de Pascal: %s\n\n", $2);
        free($2);
    }
    uses_clause
    declarations
    compound_statement DOT
    {
        generate_python_footer();
    }
    ;

uses_clause:
    /* vacío */
    | USES identifier_list SEMICOLON
    {
        fprintf(output_file, "# Uses clause - importaciones no traducidas\n\n");
    }
    ;

declarations:
    /* vacío */
    | declarations variable_declaration_block
    | declarations function_declaration
    | declarations procedure_declaration
    | declarations const_declaration_block
    | declarations label_declaration_block
    ;

variable_declaration_block:
    VAR variable_declarations
    {
        fprintf(output_file, "# Variables globales inicializadas\n\n");
    }
    ;

variable_declarations:
    variable_declaration
    | variable_declarations variable_declaration
    ;

variable_declaration:
    identifier_list COLON type SEMICOLON
    {
        // Generar inicializaciones reales para cada variable
        char* type_str = $3;
        
        // Procesar la lista de identificadores
        process_variable_list_for_declaration($1, type_str);
        
        free($1);
        free($3);
    }
    ;

const_declaration_block:
    CONST constant_declarations
    ;

constant_declarations:
    constant_declaration
    | constant_declarations constant_declaration
    ;

constant_declaration:
    IDENTIFIER EQUAL constant_value SEMICOLON
    {
        generate_indent();
        fprintf(output_file, "%s = %s\n", $1, $3);
        free($1);
        free($3);
    }
    ;

constant_value:
    NUMBER
    {
        char* result = malloc(20);
        sprintf(result, "%d", $1);
        $$ = result;
    }
    | REAL_NUM
    {
        char* result = malloc(30);
        sprintf(result, "%.2f", $1);
        $$ = result;
    }
    | STRING_VAL
    {
        char* result = malloc(strlen($1) + 3);
        sprintf(result, "\"%s\"", $1);
        free($1);
        $$ = result;
    }
    | TRUE_VAL
    {
        $$ = strdup("True");
    }
    | FALSE_VAL
    {
        $$ = strdup("False");
    }
    ;

label_declaration_block:
    LABEL label_list SEMICOLON
    {
        fprintf(output_file, "# Etiquetas declaradas\n");
    }
    ;

label_list:
    label_item
    | label_list COMMA label_item
    ;

label_item:
    IDENTIFIER
    {
        free($1);
    }
    | NUMBER
    ;

function_declaration:
    FUNCTION IDENTIFIER
    {
        fprintf(output_file, "def %s(", $2);
        strcpy(current_function, $2);
        free($2);
    }
    formal_parameter_list COLON type SEMICOLON
    {
        fprintf(output_file, "):\n");
        indent_level++;
        generate_indent();
        fprintf(output_file, "result = %s\n", get_default_value($6));
        free($6);
    }
    function_body
    {
        generate_indent();
        fprintf(output_file, "return result\n");
        indent_level--;
        fprintf(output_file, "\n");
        strcpy(current_function, "");
    }
    ;

procedure_declaration:
    PROCEDURE IDENTIFIER
    {
        fprintf(output_file, "def %s(", $2);
        free($2);
    }
    formal_parameter_list SEMICOLON
    {
        fprintf(output_file, "):\n");
        indent_level++;
    }
    procedure_body
    {
        indent_level--;
        fprintf(output_file, "\n");
    }
    ;

function_body:
    local_declarations
    compound_statement SEMICOLON
    ;

procedure_body:
    local_declarations
    compound_statement SEMICOLON
    ;

local_declarations:
    /* vacío */
    | local_declarations local_variable_declaration_block
    | local_declarations local_const_declaration_block
    ;

local_variable_declaration_block:
    VAR local_variable_declarations
    {
        generate_indent();
        fprintf(output_file, "# Variables locales inicializadas\n");
    }
    ;

local_const_declaration_block:
    CONST local_constant_declarations
    ;

local_constant_declarations:
    local_constant_declaration
    | local_constant_declarations local_constant_declaration
    ;

local_constant_declaration:
    IDENTIFIER EQUAL constant_value SEMICOLON
    {
        generate_indent();
        fprintf(output_file, "%s = %s\n", $1, $3);
        free($1);
        free($3);
    }
    ;

local_variable_declarations:
    local_variable_declaration
    | local_variable_declarations local_variable_declaration
    ;

local_variable_declaration:
    identifier_list COLON type SEMICOLON
    {
        // Inicializar variables locales con valores por defecto
        char* type_str = $3;
        process_variable_list_for_declaration($1, type_str);
        free($1);
        free($3);
    }
    ;

formal_parameter_list:
    /* vacío */
    | LPAREN parameter_sections RPAREN
    ;

parameter_sections:
    parameter_section
    | parameter_sections SEMICOLON parameter_section
    {
        fprintf(output_file, ", ");
    }
    ;

parameter_section:
    identifier_list COLON type
    {
        // Procesar parámetros normales
        fprintf(output_file, "%s", $1);
        free($1);
        free($3);
    }
    | VAR identifier_list COLON type
    {
        // Procesar parámetros por referencia
        fprintf(output_file, "%s", $2);
        free($2);
        free($4);
    }
    ;

identifier_list:
    IDENTIFIER
    {
        // Guardar el primer identificador
        $$ = strdup($1);
        free($1);
    }
    | identifier_list COMMA IDENTIFIER
    {
        // Concatenar identificadores separados por comas
        char* new_list = malloc(strlen($1) + strlen($3) + 2);
        sprintf(new_list, "%s,%s", $1, $3);
        free($1);
        free($3);
        $$ = new_list;
    }
    ;

type:
    INTEGER_TYPE
    {
        $$ = strdup("int");
    }
    | REAL_TYPE
    {
        $$ = strdup("float");
    }
    | BOOLEAN_TYPE
    {
        $$ = strdup("bool");
    }
    | STRING_TYPE
    {
        $$ = strdup("str");
    }
    | IDENTIFIER
    {
        $$ = $1;
    }
    | array_type
    {
        $$ = strdup("list");
    }
    | record_type
    {
        $$ = strdup("dict");
    }
    | set_type
    {
        $$ = strdup("set");
    }
    | pointer_type
    {
        $$ = strdup("object");
    }
    ;

array_type:
    ARRAY '[' subrange_type ']' OF type
    {
        generate_indent();
        fprintf(output_file, "# Array type declaration\n");
        free($6);
    }
    ;

subrange_type:
    NUMBER RANGE_DOTS NUMBER
    ;

record_type:
    RECORD field_list END
    {
        generate_indent();
        fprintf(output_file, "# Record type - usar clase o diccionario\n");
    }
    ;

field_list:
    field_declaration
    | field_list SEMICOLON field_declaration
    ;

field_declaration:
    identifier_list COLON type
    {
        free($1);
        free($3);
    }
    ;

set_type:
    SET OF type
    {
        generate_indent();
        fprintf(output_file, "# Set type - usar conjunto de Python\n");
        free($3);
    }
    ;

pointer_type:
    POINTER type
    {
        generate_indent();
        fprintf(output_file, "# Pointer type - manejo de referencias\n");
        free($2);
    }
    ;

compound_statement:
    T_BEGIN
    statement_sequence END
    ;

statement_sequence:
    statement
    | statement_sequence SEMICOLON statement
    | statement_sequence SEMICOLON
    ;

statement:
    simple_statement
    | structured_statement
    | empty_statement
    | label_statement
    ;

empty_statement:
    /* vacío */
    {
        generate_indent();
        fprintf(output_file, "pass\n");
    }
    ;

label_statement:
    IDENTIFIER COLON statement
    {
        generate_indent();
        fprintf(output_file, "# Label: %s\n", $1);
        free($1);
    }
    | NUMBER COLON statement
    {
        generate_indent();
        fprintf(output_file, "# Label: %d\n", $1);
    }
    ;

structured_statement:
    compound_statement
    | if_statement
    | while_statement
    | for_statement
    | repeat_statement
    | case_statement
    | with_statement
    | goto_statement
    | try_except_finally_statement
    ;

if_statement:
    IF
    {
        generate_indent();
        fprintf(output_file, "if ");
    }
    expression THEN
    {
        fprintf(output_file, ":\n");
        indent_level++;
    }
    statement
    {
        indent_level--;
    }
    | IF
    {
        generate_indent();
        fprintf(output_file, "if ");
    }
    expression THEN
    {
        fprintf(output_file, ":\n");
        indent_level++;
    }
    statement ELSE
    {
        indent_level--;
        generate_indent();
        fprintf(output_file, "else:\n");
        indent_level++;
    }
    statement
    {
        indent_level--;
    }
    ;

case_statement:
    CASE
    {
        generate_indent();
        fprintf(output_file, "_case_var = ");
    }
    case_expression OF
    {
        fprintf(output_file, "\n");
        free($3);
    }
    case_alternatives
    case_else_part
    END
    {
        generate_indent();
        fprintf(output_file, "# End case\n");
    }
    ;

case_expression:
    expression
    {
        $$ = strdup(""); // Placeholder
    }
    ;

case_alternatives:
    case_alternative
    | case_alternatives case_alternative
    ;

case_alternative:
    case_label_list COLON
    {
        fprintf(output_file, ":\n");
        indent_level++;
    }
    statement SEMICOLON
    {
        indent_level--;
    }
    ;

case_label_list:
    case_label
    {
        generate_indent();
        fprintf(output_file, "if _case_var == ");
    }
    | case_label_list COMMA case_label
    {
        fprintf(output_file, " or _case_var == ");
    }
    ;

case_label:
    NUMBER
    {
        fprintf(output_file, "%d", $1);
    }
    | IDENTIFIER
    {
        fprintf(output_file, "%s", $1);
        free($1);
    }
    ;

case_else_part:
    /* vacío */
    | ELSE
    {
        generate_indent();
        fprintf(output_file, "else:\n");
        indent_level++;
    }
    statement_sequence
    {
        indent_level--;
    }
    ;

with_statement:
    WITH variable_access DO statement
    {
        generate_indent();
        fprintf(output_file, "# With statement - acceso directo a campos\n");
    }
    ;

variable_access:
    IDENTIFIER
    {
        fprintf(output_file, "# Access to %s", $1);
        free($1);
    }
    ;

goto_statement:
    GOTO label_reference
    {
        generate_indent();
        fprintf(output_file, "# GOTO no soportado directamente - usar funciones\n");
    }
    ;

label_reference:
    IDENTIFIER
    {
        free($1);
    }
    | NUMBER
    ;

try_except_finally_statement:
    TRY
    {
        generate_indent();
        fprintf(output_file, "try:\n");
        indent_level++;
    }
    statement_sequence except_part finally_part END
    {
        generate_indent();
        fprintf(output_file, "# End try block\n");
    }
    ;

except_part:
    /* vacío */
    | EXCEPT
    {
        indent_level--;
        generate_indent();
        fprintf(output_file, "except Exception as e:\n");
        indent_level++;
    }
    statement_sequence
    {
        indent_level--;
    }
    ;

finally_part:
    /* vacío */
    | FINALLY
    {
        generate_indent();
        fprintf(output_file, "finally:\n");
        indent_level++;
    }
    statement_sequence
    {
        indent_level--;
    }
    ;

simple_statement:
    assignment_statement
    | procedure_statement
    | empty_statement
    ;

assignment_statement:
    variable_reference ASSIGN expression
    {
        fprintf(output_file, "\n");
    }
    ;

variable_reference:
    IDENTIFIER
    {
        generate_indent();
        if (strlen(current_function) > 0 && strcmp($1, current_function) == 0) {
            fprintf(output_file, "result = ");
        } else {
            fprintf(output_file, "%s = ", $1);
        }
        free($1);
    }
    | IDENTIFIER '[' 
    {
        generate_indent();
        fprintf(output_file, "%s[", $1);
        free($1);
    }
    expression ']'
    {
        fprintf(output_file, "] = ");
    }
    | IDENTIFIER DOT IDENTIFIER
    {
        generate_indent();
        fprintf(output_file, "%s.%s = ", $1, $3);
        free($1);
        free($3);
    }
    ;

while_statement:
    WHILE
    {
        generate_indent();
        fprintf(output_file, "while ");
    }
    expression DO
    {
        fprintf(output_file, ":\n");
        indent_level++;
    }
    statement
    {
        indent_level--;
    }
    ;

for_statement:
    FOR IDENTIFIER ASSIGN
    {
        generate_indent();
        fprintf(output_file, "for %s in range(", $2);
        free($2);
    }
    expression TO expression DO
    {
        fprintf(output_file, ", ");
        fprintf(output_file, " + 1):\n");
        indent_level++;
    }
    statement
    {
        indent_level--;
    }
    ;

repeat_statement:
    REPEAT
    {
        generate_indent();
        fprintf(output_file, "while True:\n");
        indent_level++;
    }
    statement_sequence UNTIL
    {
        generate_indent();
        fprintf(output_file, "if ");
    }
    expression
    {
        fprintf(output_file, ":\n");
        indent_level++;
        generate_indent();
        fprintf(output_file, "break\n");
        indent_level -= 2;
    }
    ;

procedure_statement:
    write_statement
    | read_statement
    | CLRSCR
    {
        generate_indent();
        fprintf(output_file, "import os; os.system('clear' if os.name == 'posix' else 'cls')\n");
    }
    | procedure_call
    ;

procedure_call:
    IDENTIFIER LPAREN 
    {
        generate_indent();
        fprintf(output_file, "%s(", $1);
        free($1);
    }
    actual_parameter_list RPAREN
    {
        fprintf(output_file, ")\n");
    }
    | IDENTIFIER
    {
        generate_indent();
        fprintf(output_file, "%s()\n", $1);
        free($1);
    }
    ;

write_statement:
    WRITE LPAREN 
    {
        generate_indent();
        fprintf(output_file, "print(");
    }
    output_list RPAREN
    {
        fprintf(output_file, ", end='')\n");
    }
    | WRITELN LPAREN 
    {
        generate_indent();
        fprintf(output_file, "print(");
    }
    output_list RPAREN
    {
        fprintf(output_file, ")\n");
    }
    | WRITELN
    {
        generate_indent();
        fprintf(output_file, "print()\n");
    }
    ;

output_list:
    output_value
    | output_list COMMA 
    {
        fprintf(output_file, ", ");
    }
    output_value
    ;

output_value:
    expression
    ;


read_statement:
    READ LPAREN input_variable_list RPAREN
    {
        // Las variables individuales se manejan en input_variable_list
    }
    | READLN LPAREN input_variable_list RPAREN
    {
        // Las variables individuales se manejan en input_variable_list
    }
    | READLN
    {
        generate_indent();
        fprintf(output_file, "input()  # readln sin parámetros\n");
    }
    ;

input_variable_list:
    input_variable
    | input_variable_list COMMA input_variable
    ;

input_variable:
    IDENTIFIER
    {
        generate_indent();
        fprintf(output_file, "%s = input(\"Ingrese %s: \")\n", $1, $1);
        
        // Conversión de tipo simplificada
        generate_indent();
        fprintf(output_file, "try:\n");
        indent_level++;
        generate_indent();
        fprintf(output_file, "if '.' in %s:\n", $1);
        indent_level++;
        generate_indent();
        fprintf(output_file, "%s = float(%s)\n", $1, $1);
        indent_level--;
        generate_indent();
        fprintf(output_file, "else:\n");
        indent_level++;
        generate_indent();
        fprintf(output_file, "%s = int(%s)\n", $1, $1);
        indent_level--;
        indent_level--;
        generate_indent();
        fprintf(output_file, "except ValueError:\n");
        indent_level++;
        generate_indent();
        fprintf(output_file, "pass  # Mantener como string\n");
        indent_level--;
        
        free($1);
    }
    ;


actual_parameter_list:
    /* vacío */
    | actual_parameter_sequence
    ;

actual_parameter_sequence:
    actual_parameter
    | actual_parameter_sequence COMMA 
    {
        fprintf(output_file, ", ");
    }
    actual_parameter
    ;

actual_parameter:
    expression
    ;

expression:
    simple_expression
    | simple_expression relational_operator simple_expression
    ;

relational_operator:
    EQUAL           { fprintf(output_file, " == "); }
    | NOT_EQUAL     { fprintf(output_file, " != "); }
    | LESS          { fprintf(output_file, " < "); }
    | GREATER       { fprintf(output_file, " > "); }
    | LESS_EQUAL    { fprintf(output_file, " <= "); }
    | GREATER_EQUAL { fprintf(output_file, " >= "); }
    | IN            { fprintf(output_file, " in "); }
    ;

simple_expression:
    term
    | sign term
    | simple_expression adding_operator term
    ;

sign:
    PLUS
    | MINUS         { fprintf(output_file, "-"); }
    ;

adding_operator:
    PLUS            { fprintf(output_file, " + "); }
    | MINUS         { fprintf(output_file, " - "); }
    | OR            { fprintf(output_file, " or "); }
    ;

term:
    factor
    | term multiplying_operator factor
    ;

multiplying_operator:
    MULTIPLY        { fprintf(output_file, " * "); }
    | DIVIDE        { fprintf(output_file, " / "); }
    | DIV           { fprintf(output_file, " // "); }
    | MOD           { fprintf(output_file, " %% "); }
    | AND           { fprintf(output_file, " and "); }
    ;

factor:
    NUMBER          { fprintf(output_file, "%d", $1); }
    | REAL_NUM      { fprintf(output_file, "%.2f", $1); }
    | STRING_VAL    { fprintf(output_file, "\"%s\"", $1); free($1); }
    | TRUE_VAL      { fprintf(output_file, "True"); }
    | FALSE_VAL     { fprintf(output_file, "False"); }
    | variable_access_factor
    | function_call
    | LPAREN 
    {
        fprintf(output_file, "(");
    }
    expression RPAREN
    {
        fprintf(output_file, ")");
    }
    | NOT 
    {
        fprintf(output_file, "not ");
    }
    factor
    | set_constructor
    | POINTER_DEREF variable_access_factor
    {
        fprintf(output_file, " # Desreferencia de puntero");
    }
    | ADDRESS_OF variable_access_factor
    {
        fprintf(output_file, " # Dirección de memoria");
    }
    ;


variable_access_factor:
    IDENTIFIER
    {
        fprintf(output_file, "%s", $1);
        free($1);
    }
    | IDENTIFIER '[' 
    {
        fprintf(output_file, "%s[", $1);
        free($1);
    }
    expression ']'
    {
        fprintf(output_file, "]");
    }
    | IDENTIFIER DOT IDENTIFIER
    {
        fprintf(output_file, "%s.%s", $1, $3);
        free($1);
        free($3);
    }
    ;

set_constructor:
    '[' element_list ']'
    {
        fprintf(output_file, "{");
        fprintf(output_file, "}");
    }
    | '[' ']'
    {
        fprintf(output_file, "set()");
    }
    ;

element_list:
    element
    | element_list COMMA element
    {
        fprintf(output_file, ", ");
    }
    ;

element:
    expression
    | expression RANGE_DOTS expression
    {
        fprintf(output_file, " # Range de ");
        fprintf(output_file, " a ");
    }
    ;

function_call:
    IDENTIFIER LPAREN 
    {
        fprintf(output_file, "%s(", $1);
        free($1);
    }
    actual_parameter_list RPAREN
    {
        fprintf(output_file, ")");
    }
    ;

%%

void yyerror(const char* msg) {
    fprintf(stderr, "Error sintáctico en línea %d: %s\n", yylineno, msg);
}

void generate_indent() {
    for(int i = 0; i < indent_level; i++) {
        fprintf(output_file, "    ");
    }
}

void generate_python_header() {
    fprintf(output_file, "#!/usr/bin/env python3\n");
    fprintf(output_file, "# -*- coding: utf-8 -*-\n");
    fprintf(output_file, "# Código Python generado desde Pascal\n");
    fprintf(output_file, "import sys\n");
    fprintf(output_file, "import os\n\n");
}

void generate_python_footer() {
    fprintf(output_file, "\n# Fin del programa\n");
}

void generate_variable_initialization(char* var_name, char* type_str) {
    generate_indent();
    char* default_val = get_default_value(type_str);
    fprintf(output_file, "%s = %s\n", var_name, default_val);
}

void process_variable_list_for_declaration(char* var_list, char* type_str) {
    if (!var_list || !type_str) return;
    
    char* var_list_copy = strdup(var_list);
    char* default_val = get_default_value(type_str);
    
    char* token = strtok(var_list_copy, ",");
    while (token != NULL) {
        // Eliminar espacios en blanco al inicio y final
        while (*token == ' ') token++;
        char* end = token + strlen(token) - 1;
        while (end > token && *end == ' ') *end-- = '\0';
        
        // Generar inicialización de variable
        generate_indent();
        fprintf(output_file, "%s = %s\n", token, default_val);
        
        token = strtok(NULL, ",");
    }
    
    free(var_list_copy);
}
char* generate_label() {
    char* label = malloc(20);
    sprintf(label, "_label_%d", label_counter++);
    return label;
}

char* get_default_value(const char* type) {
    if (strcmp(type, "int") == 0) {
        return "0";
    } else if (strcmp(type, "float") == 0) {
        return "0.0";
    } else if (strcmp(type, "bool") == 0) {
        return "False";
    } else if (strcmp(type, "str") == 0) {
        return "\"\"";
    } else if (strcmp(type, "list") == 0) {
        return "[]";
    } else if (strcmp(type, "dict") == 0) {
        return "{}";
    } else if (strcmp(type, "set") == 0) {
        return "set()";
    } else {
        return "None";
    }
}
