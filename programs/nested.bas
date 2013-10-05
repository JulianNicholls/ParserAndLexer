REM *** TEST NESTED FOR LOOPS ***
REM

PRINT "   ";
FOR I = 2 TO 25
  IF I < 10 THEN PRINT " ";
  PRINT " ";I;" ";
NEXT

PRINT

FOR I = 2 TO 25
  IF I < 10 THEN PRINT " ";
  PRINT I;" ";
  FOR J = 2 TO I
    K = I * J
    IF K < 100 THEN PRINT " ";
    IF K < 10 THEN PRINT " ";
    PRINT K;" ";
  NEXT J
  PRINT
NEXT I
