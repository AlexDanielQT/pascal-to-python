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