%{
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "parser.tab.h"

extern int line_num;
extern FILE* output_file;

void yyerror(const char* msg);
char* strdup_custom(const char* s);
%}

%option noyywrap
%option yylineno
%option nounput
%option noinput
%option case-insensitive

DIGIT       [0-9]
LETTER      [a-zA-Z]
IDENTIFIER  {LETTER}({LETTER}|{DIGIT}|_)*
INTEGER     {DIGIT}+
REAL        {DIGIT}+\.{DIGIT}+
STRING      \"([^\"]|\"\")*\"
COMMENT     \{[^}]*\}
WHITESPACE  [ \t\r]+
NEWLINE     \n

%%

{COMMENT}           {}
{WHITESPACE}        {}
{NEWLINE}           { line_num++; }

"program"           { return PROGRAM; }
"uses"              { return USES; }
"var"               { return VAR; }
"begin"             { return T_BEGIN; }
"end"               { return END; }
"if"                { return IF; }
"then"              { return THEN; }
"else"              { return ELSE; }
"while"             { return WHILE; }
"do"                { return DO; }
"for"               { return FOR; }
"to"                { return TO; }
"repeat"            { return REPEAT; }
"until"             { return UNTIL; }
"procedure"         { return PROCEDURE; }
"function"          { return FUNCTION; }
"integer"           { return INTEGER_TYPE; }
"real"              { return REAL_TYPE; }
"boolean"           { return BOOLEAN_TYPE; }
"string"            { return STRING_TYPE; }
"true"              { return TRUE_VAL; }
"false"             { return FALSE_VAL; }
"and"               { return AND; }
"or"                { return OR; }
"not"               { return NOT; }
"div"               { return DIV; }
"mod"               { return MOD; }
"writeln"           { return WRITELN; }
"write"             { return WRITE; }
"readln"            { return READLN; }
"read"              { return READ; }
"clrscr"            { return CLRSCR; }

{IDENTIFIER}        { yylval.str = strdup_custom(yytext); return IDENTIFIER; }
{INTEGER}           { yylval.num = atoi(yytext); return NUMBER; }
{REAL}              { yylval.real = atof(yytext); return REAL_NUM; }
{STRING}            { 
                      /* Remover comillas y procesar escape de comillas dobles */
                      char* str = malloc(strlen(yytext) + 1);
                      int i, j;
                      for(i = 1, j = 0; i < strlen(yytext) - 1; i++, j++) {
                          if(yytext[i] == '"' && yytext[i+1] == '"') {
                              str[j] = '"';
                              i++;
                          } else {
                              str[j] = yytext[i];
                          }
                      }
                      str[j] = '\0';
                      yylval.str = str;
                      return STRING_VAL; 
                    }

":="                { return ASSIGN; }
"="                 { return EQUAL; }
"<>"                { return NOT_EQUAL; }
"<="                { return LESS_EQUAL; }
">="                { return GREATER_EQUAL; }
"<"                 { return LESS; }
">"                 { return GREATER; }
"+"                 { return PLUS; }
"-"                 { return MINUS; }
"*"                 { return MULTIPLY; }
"/"                 { return DIVIDE; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }
";"                 { return SEMICOLON; }
":"                 { return COLON; }
"."                 { return DOT; }
","                 { return COMMA; }

.                   { 
                      fprintf(stderr, "Error léxico: caracter no reconocido '%c' en línea %d\n", 
                              yytext[0], yylineno);
                      return yytext[0];
                    }

%%

char* strdup_custom(const char* s) {
    char* result = malloc(strlen(s) + 1);
    if (result) {
        strcpy(result, s);
    }
    return result;
}