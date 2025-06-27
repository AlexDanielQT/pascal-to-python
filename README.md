# Pascal to Python Translator

Un traductor de código Pascal a Python desarrollado en C utilizando Flex (lexer) y Bison (parser). Este proyecto permite convertir automáticamente programas escritos en Pascal a su equivalente en Python.

## Características

- **Análisis léxico completo**: Reconoce tokens de Pascal incluyendo palabras clave, identificadores, números, cadenas y operadores
- **Análisis sintáctico robusto**: Parser basado en gramática BNF que maneja la estructura completa de Pascal
- **Traducción automática**: Convierte construcciones Pascal a Python equivalente
- **Soporte para**:
  - Declaraciones de variables y funciones
  - Estructuras de control (if/then/else, while, for, repeat/until)
  - Operaciones aritméticas y lógicas
  - Entrada/salida (readln, writeln)
  - Funciones y procedimientos
  - Comentarios y documentación

## Estructura del Proyecto

```
├── lexer.l          # Analizador léxico (Flex)
├── parser.y         # Analizador sintáctico (Bison)
├── main.c           # Programa principal
├── Makefile         # Script de compilación
├── Fermat.pas       # Archivo de ejemplo
└── README.md        # Este archivo
```

## Requisitos

- **Sistema operativo**: Linux/Unix (probado en Ubuntu/Debian)
- **Compiladores y herramientas**:
  - GCC (GNU Compiler Collection)
  - Flex (generador de analizadores léxicos)
  - Bison (generador de analizadores sintácticos)
  - Make

### Instalación de dependencias

En sistemas Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install flex bison gcc make
```

O usar el comando del Makefile:
```bash
make install-deps
```

## Compilación

Para compilar el traductor:

```bash
make clean
make
```

Esto generará el ejecutable `pascal2python`.

## Uso

### Sintaxis básica
```bash
./pascal2python <archivo_pascal> [archivo_salida]
```

### Parámetros
- `archivo_pascal`: Archivo fuente Pascal (.pas) - **requerido**
- `archivo_salida`: Archivo Python de salida (opcional, por defecto: `salida.py`)

### Ejemplos

```bash
# Traducir Fermat.pas a salida.py (por defecto)
./pascal2python Fermat.pas

# Traducir a un archivo específico
./pascal2python Fermat.pas programa.py

# Ver el resultado
cat salida.py
```

### Ejemplo completo
```bash
make clean
make
./pascal2python Fermat.pas
cat salida.py
```

## Ejemplo de Traducción

### Código Pascal (Fermat.pas)
```pascal
program FermatHelloWorld;
uses crt;

var
  n, total, x, y, z: integer;

function exp(i, n: integer): integer;
var
  ans, j: integer;
begin
  ans := 1;
  for j := 1 to n do
  begin
    ans := ans * i;
  end;
  exp := ans;
end;

begin
  clrscr;
  readln(n);
  total := 3;
  
  while true do
  begin
    for x := 1 to total - 2 do
      for y := 1 to total - x - 1 do
      begin
        z := total - x - y;
        if exp(x, n) + exp(y, n) = exp(z, n) then
          writeln("hola, mundo");
      end;
    total := total + 1;
  end;
end.
```

### Código Python generado
```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Código Python generado desde Pascal

# Traducido de Pascal: FermatHelloWorld

# Uses clause - importaciones no traducidas

def exp(i, n):
    # Variables locales declaradas
    ans = 1
    for j in range(1, n + 1):
        ans = ans * i
    return ans

# Variables globales declaradas
# clrscr - limpiar pantalla (no implementado)
n = int(input())
total = 3
while True:
    for x in range(1, total - 2 + 1):
        for y in range(1, total - x - 1 + 1):
            z = total - x - y
            if exp(x, n) + exp(y, n) == exp(z, n):
                print("hola, mundo")
    total = total + 1

# Fin del programa
```

## Características de la Traducción

### Elementos soportados

| Pascal             | Python                   |  Notas                  |
|--------------------|--------------------------|-------------------------|
| `program`          | `# Traducido de Pascal:` | Comentario informativo  |
| `var`              | Variables globales       | Declaración implícita   |
| `begin...end`      | Bloques indentados       | Indentación automática  |
| `if...then...else` | `if...else`              | Traducción directa      |
| `while...do`       | `while`                  | Traducción directa      |
| `for...to...do`    | `for...in range()`       | Conversión a range()    |
| `repeat...until`   | `while True` + `break`   | Lógica invertida        |
| `writeln()`        | `print()`                | Traducción directa      |
| `readln()`         | `input()`                | Con conversión de tipos |
| `function`         | `def`                    | Con `return` automático |
| `procedure`        | `def`                    | Sin valor de retorno    |
| `:=`               | `=`                      | Operador de asignación  |
| `=`                | `==`                     | Operador de comparación |

### Limitaciones

- **Tipos de datos**: No se hace verificación estricta de tipos
- **Arrays**: No implementado completamente
- **Records**: No soportado
- **Punteros**: No soportado
- **Archivos**: No soportado
- **Bibliotecas**: `uses` se traduce como comentario

## Comandos del Makefile

```bash
make          # Compilar el traductor
make clean    # Limpiar archivos generados
make test     # Ejecutar con archivo de prueba
make install-deps # Instalar dependencias
make help     # Mostrar ayuda
```

## Desarrollo y Extensión

### Estructura del analizador

1. **Lexer (lexer.l)**: Define tokens y patrones léxicos
2. **Parser (parser.y)**: Define gramática y reglas de traducción
3. **Main (main.c)**: Maneja archivos de entrada y salida

### Agregar nuevas características

1. Modificar `lexer.l` para nuevos tokens
2. Actualizar `parser.y` con nuevas reglas gramaticales
3. Recompilar con `make`

## Solución de Problemas

### Errores comunes

- **"Error léxico"**: Caracter no reconocido en el código Pascal
- **"Error sintáctico"**: Estructura Pascal no válida
- **"No se puede abrir archivo"**: Verificar ruta y permisos del archivo

### Debug

El programa muestra información sobre:
- Línea donde ocurre el error
- Tipo de error (léxico/sintáctico)
- Archivos de entrada y salida utilizados

## Contribución

Para contribuir al proyecto:

1. Fork el repositorio
2. Crea una rama para tu característica
3. Implementa los cambios
4. Prueba con diferentes archivos Pascal
5. Envía un pull request

## Licencia

Este proyecto está disponible bajo licencia MIT. Ver archivo LICENSE para más detalles.

## Autor

Desarrollado como proyecto académico para el curso de Compiladores.