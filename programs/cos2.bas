REM *** COS X PART 2 ***
REM
INPUT "X IN DEGREES: ";X1

X = (X1*PI/180) ^ 2
T=1
C=1
VAL=COS(SQR(X))
LOOPS=0
FOR I = 2 TO 40 STEP 2
  LOOPS = LOOPS + 1
  T = -1 * T * X / ((I - 1) * I)
  C = C + T
  IF ABS(C-VAL) < 0.000001 THEN I=60
NEXT I

PRINT
PRINT "Calculated COS(";X1;") = ";C
PRINT "Built-in   COS(";X1;") = ";VAL
PRINT "Terms: ";LOOPS
PRINT "*******************"
