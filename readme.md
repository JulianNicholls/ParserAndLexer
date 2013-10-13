# BasicParser

There is a parser and its associated lexer. The parser is nominally for 
BASIC, and is done far enough to run simple programs.


## Significant parts of BASIC not done

* GOSUB / RETURN, and ON ... GOTO
* DEF FN
* PRINT TAB
* ARRAYS
* File Operations: OPEN, CLOSE, INPUT#, PRINT#
* INPUT of multiple variables on one line
* AND, OR, NOT in conditionals

DATA, READ and RESTORE added in this version.


## Useful Parts

There are some useful parts to be had.

1. The Lexer is fairly generic and could be easily used as a basis for other 
parsers.

2. The Parser has an arithmetic expression recogniser which handles add, 
subtract, multiply, divide, power, modulo, and a number for functions. 
It also recognises variables and bracketed expressions.

3. There is a whole set of rspec tests that double as examples of what can 
be parsed out. The tests for the expression and inequality analysers are
separated out from the rest.


## Example programs

There are some example programs in the programs directory.
