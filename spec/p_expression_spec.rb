require_relative '../parser.rb'

class Parser

  public :expression
  
  def feed_expression str
    @line = str
    @lexer.from @line
  end
end

describe Parser do

  before :all do
    @parser = Parser.new
    @parser.line_do "A1 = 10"
    @parser.line_do "A2 = 20"
    @parser.line_do "A3 = 30"
  end

  describe ".expression" do
    describe "Simplest" do
      it "should return an integer constant" do
        @parser.feed_expression "25"
        @parser.expression.should eq 25
      end

      it "should return a float constant" do
        @parser.feed_expression "25.5"
        @parser.expression.should eq 25.5
      end
      
      it "should simply return the value for a variable" do
        @parser.feed_expression "A1"
        @parser.expression.should eq 10
      end
    end
    
    describe "Simple operations" do
      it "should return an addition" do
        @parser.feed_expression "2 + 5"
        @parser.expression.should eq 7
      end
      
      it "should return a subtraction" do
        @parser.feed_expression "10 - 6"
        @parser.expression.should eq 4
      end
      
      it "should return a multiplication" do
        @parser.feed_expression "2 * 5"
        @parser.expression.should eq 10
      end
      
      it "should return a division" do
        @parser.feed_expression "20 / 5"
        @parser.expression.should eq 4
      end

      it "should return a modulo" do
        @parser.feed_expression "15 % 7"
        @parser.expression.should eq 1
      end

      it "should return an exponent" do
        @parser.feed_expression "2 ^ 10"
        @parser.expression.should eq 1024
      end
    end
    
    it "should accept expressions using variables" do
      @parser.feed_expression "A1 + A2 +A3"
      @parser.expression.should eq 60
    
      @parser.feed_expression "A3 * A1"
      @parser.expression.should eq 300
      
      @parser.feed_expression "A3 / 3"
      @parser.expression.should eq 10

      @parser.feed_expression "A1 + A2 - A3"
      @parser.expression.should eq 0
      
      @parser.feed_expression "A1 - A3"
      @parser.expression.should eq -20
    end
    
    it "should accept a simple bracketed expression" do
      @parser.feed_expression "(7+8)"
      @parser.expression.should eq 15
      
      @parser.feed_expression "(8 - 7)"
      @parser.expression.should eq 1
      
      @parser.feed_expression "(7*8)"
      @parser.expression.should eq 56
      
      @parser.feed_expression "(56 / 7)"
      @parser.expression.should eq 8
    end
    
    it "should accept a more complicated expression" do
      @parser.feed_expression "10 *(7+8)"
      @parser.expression.should eq 150
      
      @parser.feed_expression "A3* (A2+8)"
      @parser.expression.should eq 840
    end
    
    describe "Precedence" do
      it "should do exponentiation first" do
        @parser.feed_expression "2 + 2 ^ 5 * 10"
        @parser.expression.should eq 322
      end
      
      it "should do *, /, and % before + and -" do
        @parser.feed_expression "2 + 3 * 5"
        @parser.expression.should eq 17   # NOT 25!
      
        @parser.feed_expression "3 * 2 + 3 * 5"
        @parser.expression.should eq 21   # NOT 75
      end

      it "should allow bracketing to change it" do
        @parser.feed_expression "3 * (2 + 3) * 5"
        @parser.expression.should eq 75

        @parser.feed_expression "(2 ^ 10) ^ 2"
        @parser.expression.should eq 1048576
      end
    end
  end
  
  describe "Exceptions" do
    it "should be thrown for a missing right bracket" do
      @parser.feed_expression "10 *(7+8"
      expect { @parser.expression }.to raise_error( ParserError )
    end
      
    it "should be thrown for a completely illegal expression" do
      @parser.feed_expression "10 + 'str'"
      expect { @parser.expression }.to raise_error( ParserError )
    end
  end

end