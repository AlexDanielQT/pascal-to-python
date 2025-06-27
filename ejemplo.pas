program PruebaTraductor;
var
    x, y: integer;
    nombre: string;
    activo: boolean;

begin
    x := 10;
    y := 20;
    nombre := "Hola Mundo";
    activo := true;
    
    if x < y then
        writeln("x es menor que y")
    else
        writeln("x es mayor o igual que y");
    
    while x < 15 do
    begin
        writeln("x = ", x);
        x := x + 1
    end;
    
    for x := 1 to 5 do
        writeln("Iteración: ", x);
        
    writeln("Programa terminado")
end.