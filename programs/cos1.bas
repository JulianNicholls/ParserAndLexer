REM *** COS X ***
REM
INPUT "NUMBER OF TERMS: ";N
INPUT "X IN DEGREES   : ";X1

START = TI

X = (X1*PI/180) ^ 2
T=1
C=1
FOR I = 2 TO N * 2 STEP 2
  T = -1 * T * X / ((I - 1) * I)
  C = C + T
NEXT I

FINISH = TI

PRINT
PRINT "COS(";X1;") = ";C
PRINT "*******************"
PRINT "ELAPSED TIME: ";FINISH-START
PRINT "*******************"
