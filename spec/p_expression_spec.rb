require_relative '../verybasic.rb'

class Parser

  def feed_expression str
    @line = str
  end
end

describe Parser do

  before :all do
    @parser = Parser.new
    @parser.line_do "A1 = 10"
    @parser.line_do "A2 = 20"
    @parser.line_do "A3 = 30"
    
  end

  describe ".factor" do
#    it "should simply return the value for a constant" do
#      @parser.feed_expression "25"
#      @parser.expression.should eq 25
#    end
#
#    it "should simply return the value for a variable" do
#      @parser.feed_expression "A1"
#      @parser.expression.should eq 10
#    end
  end
  
  describe ".term" do
    
  end
end