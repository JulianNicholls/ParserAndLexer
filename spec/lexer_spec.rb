require_relative '../lexer'

class Lexer
  attr_reader :str
end

describe Lexer do

  before :all do
    @lexer = Lexer.new
  end

  
  describe "Emptyness" do
    it "should not be allowed" do
      expect { @lexer.next }.to raise_error( LexerError )
    end
  end
  
  
  describe ".from" do
    it "should set the string to work on" do
      @lexer.from "12345 text"
      expect( @lexer.str ).to eq "12345 text"
    end
  end
  
  
  describe "String Finder" do
    it "should find double-quoted strings" do
      @lexer.from '"dq string"'
      expect( @lexer.next ).to eq Token.new( :string, 'dq string' )
    end
    
    it "should find single-quoted strings" do
      @lexer.from "'sq string'"
      expect( @lexer.next ).to eq Token.new( :string, 'sq string' )
    end

    it "should raise an exception for an unterminated string" do
      @lexer.from "'sq string"
      expect { @lexer.next }.to raise_exception( LexerError )
    end
  end
  
  
  describe "Number Finder" do
    it "should find integers" do
      @lexer.from "12345"
      expect( @lexer.next ).to eq Token.new( :integer, 12345 )
    end

    it "should find negative values" do
      @lexer.from "-12345"
      expect( @lexer.peek_next ).to eq Token.new( :integer, -12345 )
      expect( @lexer.next ).to eq Token.new( :integer, -12345 )
    end
    
    it "should find floating point values" do
      @lexer.from "123.45"
      expect( @lexer.next ).to eq Token.new( :float, 123.45 )
    end

    it "should raise an exception for a bad float" do
      @lexer.from "1.23.45"   # Whoops! two decimal points
      expect { @lexer.next }.to raise_error( LexerError )
    end
  end

  
  describe "Identifier Finder" do
    it "should find an identifier with just uppercase letters" do
      @lexer.from "VAR"
      expect( @lexer.next ).to eq Token.new( :ident, 'VAR' )
    end

    it "should find an identifier with just lowercase letters" do
      @lexer.from "var1"
      expect( @lexer.next ).to eq Token.new( :ident, 'var1' )
    end

    it "should find an identifier with mixed case" do
      @lexer.from "Var"
      expect( @lexer.next ).to eq Token.new( :ident, 'Var' )
    end

    it "should find an identifier with letters and numbers" do
      @lexer.from "var1"
      expect( @lexer.next ).to eq Token.new( :ident, 'var1' )
    end

    it "should find an identifier with letters, underscores and numbers" do
      @lexer.from "Var_2"
      expect( @lexer.next ).to eq Token.new( :ident, 'Var_2' )
    end
  end
  
  
  describe "Assignment Operator" do
    it "should be found" do
      @lexer.from "="
      expect( @lexer.next ).to eq Token.new( :assign )
    end
  end
  
  
  describe ".peek_next" do
    it "should return the next token, not suck it up, and leave it available for .next" do
      @lexer.from '"dq string"'
      
      expect( @lexer.peek_next ).to eq Token.new( :string, 'dq string' )
      expect( @lexer.str ).to eq '"dq string"'
      
      expect( @lexer.peek_next ).to eq Token.new( :string, 'dq string' )
      expect( @lexer.str ).to eq '"dq string"'
      
      expect( @lexer.next ).to eq Token.new( :string, 'dq string' )
   end
    
   it "should be able to parse a whole assignment" do
      @lexer.from 'A1 = -1'
      
      expect( @lexer.peek_next ).to eq Token.new( :ident, 'A1' )
      expect( @lexer.next ).to eq Token.new( :ident, 'A1' )
     
      expect( @lexer.peek_next ).to eq Token.new( :assign )
      expect( @lexer.next ).to eq Token.new( :assign )
     
      expect( @lexer.peek_next ).to eq Token.new( :integer, -1 )
      expect( @lexer.next ).to eq Token.new( :integer, -1 )
    end    
  end
  
  
  describe "Comparison Finder" do
    it "should find equality comparison" do
      @lexer.from "=="
      expect( @lexer.next ).to eq Token.new( :cmp_eq )
      expect( @lexer.next ).to eq Token.new( :eos )
    end

    it "should find inequality comparison" do
      @lexer.from "!="
      expect( @lexer.next ).to eq Token.new( :cmp_ne )
      expect( @lexer.next ).to eq Token.new( :eos )
    end

    it "should find less than comparison" do
      @lexer.from "<"
      expect( @lexer.next ).to eq Token.new( :cmp_lt )
      expect( @lexer.next ).to eq Token.new( :eos )
    end

    it "should find less then or equal to comparison" do
      @lexer.from "<="
      expect( @lexer.next ).to eq Token.new( :cmp_lte )
      expect( @lexer.next ).to eq Token.new( :eos )
   end

    it "should find greater than comparison" do
      @lexer.from ">"
      expect( @lexer.next ).to eq Token.new( :cmp_gt )
    end
    
    it "should find greater than or equal to comparison" do
      @lexer.from ">="
      expect( @lexer.next ).to eq Token.new( :cmp_gte )
    end
  end
  
  
  describe "Operator Finder" do
    it "should find the plus operator" do
      @lexer.from "+"
      expect( @lexer.next ).to eq Token.new( :plus )
    end
    
    it "should find the minus operator" do
      @lexer.from "-"
      expect( @lexer.next ).to eq Token.new( :minus )
    end
    
    it "should find the times operator" do
      @lexer.from "*"
      expect( @lexer.next ).to eq Token.new( :multiply )
    end
    
    it "should find the divide operator" do
      @lexer.from "/"
      expect( @lexer.next ).to eq Token.new( :divide )
    end
    
    it "should find the modulo operator" do
      @lexer.from "%"
      expect( @lexer.next ).to eq Token.new( :modulo )
    end
    
    it "should find the exponent operator" do
      @lexer.from "^"
      expect( @lexer.next ).to eq Token.new( :exponent )
    end
  end
  
  
  describe "End of Line Finder" do
    it "should find the LF character" do
      @lexer.from "\n"
      expect( @lexer.next ).to eq Token.new( :eol )
    end

    it "should find the CR character" do
      @lexer.from "\r"
      expect( @lexer.next ).to eq Token.new( :eol )
    end

    it "should find the CRLF combo and swallow all of it" do
      @lexer.from "\r\n"
      expect( @lexer.next ).to eq Token.new( :eol )
      expect( @lexer.next ).to eq Token.new( :eos )
    end

    it "should find the LF+CR combo and swallow all of it" do
      @lexer.from "\n\r"
      expect( @lexer.next ).to eq Token.new( :eol )
      expect( @lexer.next ).to eq Token.new( :eos )
    end

    it "should find a combination of LFs and CRs and swallow all of it" do
      @lexer.from "\n\n\r\r\n"
      expect( @lexer.next ).to eq Token.new( :eol )
      expect( @lexer.next ).to eq Token.new( :eos )
    end
  end
  
  
  describe "Bracket Finder" do
    it "should find an opening bracket" do
      @lexer.from "("
      expect( @lexer.next ).to eq Token.new( :br_open )
    end

    it "should find a closing bracket" do
      @lexer.from ")"
      expect( @lexer.next ).to eq Token.new( :br_close )
    end

    it "should find an opening square bracket" do
      @lexer.from "["
      expect( @lexer.next ).to eq Token.new( :sqbr_open )
    end

    it "should find a closing square bracket" do
      @lexer.from "]"
      expect( @lexer.next ).to eq Token.new( :sqbr_close )
    end
  end
  
  
  describe "Delimiter Finder" do
    it "should find a colon" do
      @lexer.from ":"
      expect( @lexer.next ).to eq Token.new( :colon )
    end

    it "should find a semi-colon PRINT separator" do
      @lexer.from ";"
      expect( @lexer.next ).to eq Token.new( :separator, ';' )
    end
    
    it "should find a comma PRINT separator" do
      @lexer.from ","
      expect( @lexer.next ).to eq Token.new( :separator, ',' )
    end
  end
  
  
  describe "Reserved Word" do
    it "PRINT should be found" do
      @lexer.from "PRINT"
      expect( @lexer.next ).to eq Token.new( :PRINT )
      expect( @lexer.str ).to eq ''
     end
  
    it "INPUT should be found" do
      @lexer.from "INPUT"
      expect( @lexer.next ).to eq Token.new( :INPUT )
    end

    it "LET should be found" do
      @lexer.from "LET"
      expect( @lexer.next ).to eq Token.new( :LET )
    end

    it "IF should be found" do
      @lexer.from "IF"
      expect( @lexer.next ).to eq Token.new( :IF )
    end

    it "THEN should be found" do
      @lexer.from "THEN"
      expect( @lexer.next ).to eq Token.new( :THEN )
    end

    it "FOR should be found" do
      @lexer.from "FOR"
      expect( @lexer.next ).to eq Token.new( :FOR )
    end

    it "TO should be found" do
      @lexer.from "TO"
      expect( @lexer.next ).to eq Token.new( :TO )
    end

    it "STEP should be found" do
      @lexer.from "STEP"
      expect( @lexer.next ).to eq Token.new( :STEP )
    end

    it "NEXT should be found" do
      @lexer.from "NEXT"
      expect( @lexer.next ).to eq Token.new( :NEXT )
    end

    it "END should be found" do
      @lexer.from "END"
      expect( @lexer.next ).to eq Token.new( :END )
   end

    it "STOP should be found" do
      @lexer.from "STOP"
      expect( @lexer.next ).to eq Token.new( :STOP )
    end

    it "REM should be found" do
      @lexer.from "REM"
      expect( @lexer.next ).to eq Token.new( :REM )
    end
  end
  
end
