# BasicParser

There is a parser and its associated lexer. The parser is nominally for 
BASIC, and is partly done.

## Useful Parts

There are some useful parts to be had.

1. The Lexer is fairly generic and could be easily used as a basis for other 
parsers.

2. The Parser has an arithmetic expression recogniser which handles addition, 
subtraction, multiplication, division, and modulo. It also recognises variables
and bracketed expressions.

3. There is a whole set of rspec tests that double as examples of what can 
be parsed out.
