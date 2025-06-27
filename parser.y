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

void yyerror(const char* msg);
void generate_indent();
void generate_python_header();
void generate_python_footer();
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

%token <str> IDENTIFIER STRING_VAL
%token <num> NUMBER
%token <real> REAL_NUM

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
    ;

variable_declaration_block:
    VAR variable_declarations
    {
        fprintf(output_file, "# Variables globales declaradas\n");
    }
    ;

variable_declarations:
    variable_declaration
    | variable_declarations variable_declaration
    ;

variable_declaration:
    identifier_list COLON type SEMICOLON
    ;

function_declaration:
    FUNCTION IDENTIFIER 
    {
        fprintf(output_file, "def %s(", $2);
        strcpy(current_function, $2);
        free($2);
    }
    LPAREN parameter_list RPAREN COLON type SEMICOLON
    {
        fprintf(output_file, "):\n");
        indent_level++;
    }
    function_body
    {
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
    LPAREN parameter_list RPAREN SEMICOLON
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
    ;

local_variable_declaration_block:
    VAR local_variable_declarations
    {
        generate_indent();
        fprintf(output_file, "# Variables locales declaradas\n");
    }
    ;

local_variable_declarations:
    local_variable_declaration
    | local_variable_declarations local_variable_declaration
    ;

local_variable_declaration:
    identifier_list COLON type SEMICOLON
    ;

parameter_list:
    /* vacío */
    | non_empty_parameter_list
    ;

non_empty_parameter_list:
    parameter_declaration
    | non_empty_parameter_list SEMICOLON parameter_declaration
    {
        fprintf(output_file, ", ");
    }
    ;

parameter_declaration:
    identifier_list COLON type
    ;

identifier_list:
    IDENTIFIER 
    { 
        fprintf(output_file, "%s", $1); 
        free($1); 
    }
    | identifier_list COMMA IDENTIFIER 
    { 
        fprintf(output_file, ", %s", $3); 
        free($3); 
    }
    ;

type:
    INTEGER_TYPE    { /* tipo entero */ }
    | REAL_TYPE     { /* tipo real */ }
    | BOOLEAN_TYPE  { /* tipo booleano */ }
    | STRING_TYPE   { /* tipo cadena */ }
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
    ;

structured_statement:
    compound_statement
    | if_statement
    | while_statement
    | for_statement
    | repeat_statement
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

simple_statement:
    assignment_statement
    | procedure_statement
    | /* vacío */
    ;

assignment_statement:
    IDENTIFIER 
    {
        generate_indent();
        /* Verificar si es asignación a función (return) */
        if (strlen(current_function) > 0 && strcmp($1, current_function) == 0) {
            fprintf(output_file, "return ");
        } else {
            fprintf(output_file, "%s = ", $1);
        }
        free($1);
    }
    ASSIGN expression
    {
        fprintf(output_file, "\n");
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
    expression TO 
    {
        fprintf(output_file, ", ");
    }
    expression DO
    {
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
        fprintf(output_file, "# clrscr - limpiar pantalla (no implementado)\n");
    }
    | IDENTIFIER LPAREN argument_list RPAREN
    {
        generate_indent();
        fprintf(output_file, "%s(", $1);
        fprintf(output_file, ")\n");
        free($1);
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

read_statement:
    READ LPAREN input_list RPAREN
    | READLN LPAREN input_list RPAREN
    | READLN LPAREN IDENTIFIER RPAREN
    {
        generate_indent();
        fprintf(output_file, "%s = int(input())\n", $3);
        free($3);
    }
    | READLN
    {
        generate_indent();
        fprintf(output_file, "input()  # readln sin parámetros\n");
    }
    ;

output_list:
    expression
    | output_list COMMA 
    {
        fprintf(output_file, ", ");
    }
    expression
    ;

input_list:
    IDENTIFIER 
    { 
        generate_indent();
        fprintf(output_file, "%s = input()\n", $1); 
        free($1); 
    }
    | input_list COMMA IDENTIFIER 
    { 
        generate_indent();
        fprintf(output_file, "%s = input()\n", $3); 
        free($3); 
    }
    ;

expression:
    simple_expression
    | simple_expression relop simple_expression
    ;

relop:
    EQUAL           { fprintf(output_file, " == "); }
    | NOT_EQUAL     { fprintf(output_file, " != "); }
    | LESS          { fprintf(output_file, " < "); }
    | GREATER       { fprintf(output_file, " > "); }
    | LESS_EQUAL    { fprintf(output_file, " <= "); }
    | GREATER_EQUAL { fprintf(output_file, " >= "); }
    ;

simple_expression:
    term
    | simple_expression addop term
    ;

addop:
    PLUS    { fprintf(output_file, " + "); }
    | MINUS { fprintf(output_file, " - "); }
    | OR    { fprintf(output_file, " or "); }
    ;

term:
    factor
    | term mulop factor
    ;

mulop:
    MULTIPLY    { fprintf(output_file, " * "); }
    | DIVIDE    { fprintf(output_file, " / "); }
    | DIV       { fprintf(output_file, " // "); }
    | MOD       { fprintf(output_file, " %% "); }
    | AND       { fprintf(output_file, " and "); }
    ;

factor:
    NUMBER          { fprintf(output_file, "%d", $1); }
    | REAL_NUM      { fprintf(output_file, "%.2f", $1); }
    | STRING_VAL    { fprintf(output_file, "\"%s\"", $1); free($1); }
    | TRUE_VAL      { fprintf(output_file, "True"); }
    | FALSE_VAL     { fprintf(output_file, "False"); }
    | IDENTIFIER    { fprintf(output_file, "%s", $1); free($1); }
    | function_call
    | LPAREN expression RPAREN
    | NOT factor    { fprintf(output_file, "not "); }
    | MINUS factor %prec UMINUS { fprintf(output_file, "-"); }
    ;

function_call:
    IDENTIFIER LPAREN 
    {
        fprintf(output_file, "%s(", $1);
        free($1);
    }
    argument_list RPAREN
    {
        fprintf(output_file, ")");
    }
    ;

argument_list:
    /* vacío */
    | non_empty_argument_list
    ;

non_empty_argument_list:
    expression
    | non_empty_argument_list COMMA 
    {
        fprintf(output_file, ", ");
    }
    expression
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
    fprintf(output_file, "# Código Python generado desde Pascal\n\n");
}

void generate_python_footer() {
    fprintf(output_file, "\n# Fin del programa\n");
}