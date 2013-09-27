require_relative '../lexer'

describe Lexer do

  before :all do
    @lexer = Lexer.new
  end

  describe "Emptyness" do
    it "should not be allowed" do
      expect { @lexer.next }.to raise_error( LexerError )
    end
  end
  
  describe "Strings" do
    it "should find double-quoted strings" do
      @lexer.from '"dq string"'
      @lexer.next.should == { :token => :string, :value => 'dq string' }
    end
    
    it "should find single-quoted strings" do
      @lexer.from "'sq string'"
      @lexer.next.should == { :token => :string, :value => 'sq string' }
    end

    it "should raise an exception for an unterminated string" do
      @lexer.from "'sq string"
      expect { @lexer.next }.to raise_exception( LexerError )
    end
  end
  
  describe "Numbers" do
    it "should find integers" do
      @lexer.from "12345"
      @lexer.next.should == { :token => :integer, :value => 12345 }
    end
  
    it "should find floating point values" do
      @lexer.from "123.45"
      @lexer.next.should == { :token => :float, :value => 123.45 }
    end

    it "should raise an exception for a bad float" do
      @lexer.from "1.23.45"   # Whoops! two decimal points
      expect { @lexer.next }.to raise_error( LexerError )
    end
  end

  describe "Identifiers" do
    it "should find an identifier with just letters" do
      @lexer.from "var"
      @lexer.next.should == { :token => :ident, :value => 'var' }
    end

    it "should find an identifier with letters and numbers" do
      @lexer.from "var1"
      @lexer.next.should == { :token => :ident, :value => 'var1' }
    end

    it "should find an identifier with letters, underscores and numbers" do
      @lexer.from "var_2"
      @lexer.next.should == { :token => :ident, :value => 'var_2' }
    end
  end
  
  describe "Assignment" do
    it "should be found" do
      @lexer.from "="
      @lexer.next.should == { :token => :assign }
    end
  end
  
  describe "Comparisons" do
    it "should find equality comparison" do
      @lexer.from "=="
      @lexer.next.should == { :token => :cmp_equal }
    end

    it "should find inequality comparison" do
      @lexer.from "!="
      @lexer.next.should == { :token => :comparison, :value => '!=' }
    end

    it "should find less than comparison" do
      @lexer.from "<"
      @lexer.next.should == { :token => :comparison, :value => '<' }
    end

    it "should find less then or equal to comparison" do
      @lexer.from "<="
      @lexer.next.should == { :token => :comparison, :value => '<=' }
    end

    it "should find greater than comparison" do
      @lexer.from ">"
      @lexer.next.should == { :token => :comparison, :value => '>' }
    end
    
    it "should find greater than or equal to comparison" do
      @lexer.from ">="
      @lexer.next.should == { :token => :comparison, :value => '>=' }
    end
  end
  
  describe "Operators" do
    it "should find the plus operator" do
      @lexer.from "+"
      @lexer.next.should == { :token => :operator, :value => '+' }
    end
    
    it "should find the minus operator" do
      @lexer.from "-"
      @lexer.next.should == { :token => :operator, :value => '-' }
    end
    
    it "should find the times operator" do
      @lexer.from "*"
      @lexer.next.should == { :token => :operator, :value => '*' }
    end
    
    it "should find the divide operator" do
      @lexer.from "/"
      @lexer.next.should == { :token => :operator, :value => '/' }
    end
    
    it "should find the modulo operator" do
      @lexer.from "%"
      @lexer.next.should == { :token => :operator, :value => '%' }
    end
  end
  
  describe "End of Lines" do
    it "should find the LF character" do
      @lexer.from "\n"
      @lexer.next.should == { :token => :eol }
    end

    it "should find the CR character" do
      @lexer.from "\r"
      @lexer.next.should == { :token => :eol }
    end

    it "should find the CRLF combo and swallow all of it" do
      @lexer.from "\r\n"
      @lexer.next.should == { :token => :eol }
      @lexer.next.should == { :token => :eos }
    end

    it "should find the LF+CR combo and swallow all of it" do
      @lexer.from "\n\r"
      @lexer.next.should == { :token => :eol }
      @lexer.next.should == { :token => :eos }
    end

    it "should find a combination of LFs and CRs and swallow all of it" do
      @lexer.from "\n\r\n"
      @lexer.next.should == { :token => :eol }
      @lexer.next.should == { :token => :eos }
    end
  end
  
  describe "Brackets" do
    it "should find an opening bracket" do
      @lexer.from "("
      @lexer.next.should == { :token => :br_open }
    end

    it "should find a closing bracket" do
      @lexer.from ")"
      @lexer.next.should == { :token => :br_close }
    end

    it "should find an opening square bracket" do
      @lexer.from "["
      @lexer.next.should == { :token => :sqbr_open }
    end

    it "should find a closing square bracket" do
      @lexer.from "]"
      @lexer.next.should == { :token => :sqbr_close }
    end
  end
  
  describe "Delimiters" do
    it "should find a colon" do
      @lexer.from ":"
      @lexer.next.should == { :token => :colon }
    end

    it "should find a semi-colon PRINT separator" do
      @lexer.from ";"
      @lexer.next.should == { :token => :separator, :value => ';' }
    end
    
    it "should find a comma PRINT separator" do
      @lexer.from ","
      @lexer.next.should == { :token => :separator, :value => ',' }
    end
  end
  
  describe "Reserved Word" do
    it "PRINT should be found" do
      @lexer.from "PRINT"
      @lexer.next.should == { :token => :PRINT }
    end
  
    it "INPUT should be found" do
      @lexer.from "INPUT"
      @lexer.next.should == { :token => :INPUT }
    end

    it "LET should be found" do
      @lexer.from "LET"
      @lexer.next.should == { :token => :LET }
    end

    it "IF should be found" do
      @lexer.from "IF"
      @lexer.next.should == { :token => :IF }
    end

    it "THEN should be found" do
      @lexer.from "THEN"
      @lexer.next.should == { :token => :THEN }
    end

    it "FOR should be found" do
      @lexer.from "FOR"
      @lexer.next.should == { :token => :FOR }
    end

    it "TO should be found" do
      @lexer.from "TO"
      @lexer.next.should == { :token => :TO }
    end

    it "STEP should be found" do
      @lexer.from "STEP"
      @lexer.next.should == { :token => :STEP }
    end

    it "NEXT should be found" do
      @lexer.from "NEXT"
      @lexer.next.should == { :token => :NEXT }
    end

    it "END should be found" do
      @lexer.from "END"
      @lexer.next.should == { :token => :END }
    end

    it "STOP should be found" do
      @lexer.from "STOP"
      @lexer.next.should == { :token => :STOP }
    end

    it "REM should be found" do
      @lexer.from "REM"
      @lexer.next.should == { :token => :REM }
    end
  end
  
end
