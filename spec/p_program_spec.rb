require_relative '../parser.rb'

require 'spec_helper.rb'

class Parser
  attr_reader :variables
end


describe Parser do

  before :all do
    @parser = Parser.new
  end

  describe ".do_program" do
    it "should understand a whole program" do
      output = capture_stdout do
        @parser.do_program %{
REM *** THIRD PROGRAM - FIBONACCI 20
REM
A = 1
B = 1
PRINT "1, 1, ";
FOR X = 1 TO 20
 C = B
 B = B + A
 A = C
 PRINT B;", ";
 IF X % 10 = 0 THEN PRINT
NEXT
END
}
      end
      
      expect( output ).to eq "1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, \n233, 377, 610, 987, 1597, 2584, 4181, 6765, 10946, 17711, \n"
    end
  end
end