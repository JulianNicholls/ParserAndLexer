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
  
  describe "GOTO" do
    it "should be obeyed" do
      output = capture_stdout do
        @parser.do_program %{
10 PRINT "LINE 10"
20 GOTO 40
25 END
30 PRINT "LINE 30"
40 PRINT "LINE 40"
50 GOTO 25
60 PRINT "LINE 60"
}        
      end
      
      expect( output ).to eq "LINE 10\nLINE 40\n"
    end
  end
  
  describe "READ" do
    it "should work" do
      output = capture_stdout do
        @parser.do_program %{
FOR I = 1 TO 10
  READ J
  PRINT J;", ";
NEXT
PRINT
DATA 10, 20, 30, 35, 40, 50, 55, 60, 70, 80 
PRINT "PAST DATA"
}    
      end
      
      expect( output ).to eq "10, 20, 30, 35, 40, 50, 55, 60, 70, 80, \nPAST DATA\n"
    end
  end
  
  describe "RESTORE" do
    it "should work" do
      output = capture_stdout do
        @parser.do_program %{
FOR I = 1 TO 5
  READ J
  PRINT J;", ";
NEXT
PRINT
RESTORE
FOR I = 1 TO 5
  READ J
  PRINT J;", ";
NEXT
PRINT
DATA 10, 20, 30, 35, 40
PRINT "PAST DATA"
}    
      end
      
      expect( output ).to eq "10, 20, 30, 35, 40, \n10, 20, 30, 35, 40, \nPAST DATA\n"
    end
  end
  
  describe "GOSUB" do
    it "should work as GOTO" do
      output = capture_stdout do
        @parser.do_program %{
10 PRINT "LINE 10"
20 GOSUB 40
30 PRINT "LINE 30"
40 PRINT "LINE 40"
}    
      end
      
      expect( output ).to eq "LINE 10\nLINE 40\n"
    end
  end
  
  describe "RETURN" do
    it "should work to return from GOSUB" do
      output = capture_stdout do
        @parser.do_program %{
10 PRINT "LINE 10"
20 GOSUB 40
30 PRINT "LINE 30"
35 END
40 PRINT "LINE 40"
50 RETURN
}    
      end
      
      expect( output ).to eq "LINE 10\nLINE 40\nLINE 30\n"
    end
  end
end