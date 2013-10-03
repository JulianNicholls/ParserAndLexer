REM *** TEST NESTED FOR LOOPS ***
REM

PRINT "    ";
FOR I = 2 TO 12
  IF I < 10 THEN PRINT " ";
  PRINT " ";I;" ";
NEXT

PRINT

FOR I = 2 TO 12
  IF I < 10 THEN PRINT " ";
  PRINT I;"  ";
  FOR J = 2 TO 12
    K = I * J
    IF K < 10 THEN PRINT " ";
    IF K < 100 THEN PRINT " ";
    PRINT K;" ";
  NEXT J
  PRINT
NEXT I
