# Makefile para el traductor Pascal a Python
CC = gcc
FLEX = flex
BISON = bison
CFLAGS = -Wall -g -std=c99 -D_POSIX_C_SOURCE=200809L
TARGET = pascal2python
LEXER = lexer
PARSER = parser

# Archivos fuente
LEX_FILE = $(LEXER).l
YACC_FILE = $(PARSER).y
LEX_C = lex.yy.c
YACC_C = $(PARSER).tab.c
YACC_H = $(PARSER).tab.h
MAIN_C = main.c

# Archivos objeto
OBJS = $(LEX_C:.c=.o) $(YACC_C:.c=.o) $(MAIN_C:.c=.o)

# Regla principal
all: $(TARGET)

# Compilar el ejecutable
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ -lfl

# Generar código C desde Bison (con supresión de warnings de conflictos)
$(YACC_C) $(YACC_H): $(YACC_FILE)
	$(BISON) -d $(YACC_FILE) 2>/dev/null || $(BISON) -d $(YACC_FILE)

# Generar código C desde Flex 
$(LEX_C): $(LEX_FILE) $(YACC_H)
	$(FLEX) $(LEX_FILE)

# Compilar archivos objeto
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Limpiar archivos generados
clean:
	rm -f $(OBJS) $(LEX_C) $(YACC_C) $(YACC_H) $(TARGET)

# Limpiar todo incluyendo archivos de respaldo
distclean: clean
	rm -f *~ *.bak

# Ejecutar con archivo de prueba
test: $(TARGET)
	./$(TARGET) test.pas

# Instalar dependencias (Ubuntu/Debian)
install-deps:
	sudo apt-get update
	sudo apt-get install flex bison gcc make

# Ayuda
help:
	@echo "Uso del Makefile:"
	@echo "  make          - Compilar el traductor"
	@echo "  make clean    - Limpiar archivos generados"
	@echo "  make test     - Ejecutar con archivo de prueba"
	@echo "  make install-deps - Instalar dependencias"
	@echo "  make help     - Mostrar esta ayuda"

.PHONY: all clean distclean test install-deps help