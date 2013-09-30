require_relative '../verybasic.rb'

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
    it "should simply return the value for an integer constant" do
      @parser.feed_expression "25"
      @parser.expression.should eq 25
    end

    it "should simply return the value for a float constant" do
      @parser.feed_expression "25.5"
      @parser.expression.should eq 25.5
    end

    it "should simply return the value for a variable" do
      @parser.feed_expression "A1"
      @parser.expression.should eq 10
    end
    
    it "should return the value for a simple addition" do
      @parser.feed_expression "2 + 5"
      @parser.expression.should eq 7
    end
    
    it "should return the value for a simple subtraction" do
      @parser.feed_expression "10 - 6"
      @parser.expression.should eq 4
    end
    
    it "should return the value for a simple multiplication" do
      @parser.feed_expression "2 * 5"
      @parser.expression.should eq 10
    end
    
    it "should return the value for a simple division" do
      @parser.feed_expression "20 / 5"
      @parser.expression.should eq 4
    end

    it "should return the value for a simple modulo" do
      @parser.feed_expression "15 % 7"
      @parser.expression.should eq 1
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