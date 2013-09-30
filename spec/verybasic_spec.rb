require_relative '../verybasic.rb'

class Parser
  attr_reader :variables
end


#----------------------------------------------------------------------------
# Capture the printed output so it can be examined (or ignored).
#----------------------------------------------------------------------------

def capture_stdout &block
  old_stdout  = $stdout
  fake_stdout = StringIO.new
  $stdout     = fake_stdout
  
  yield
  
  fake_stdout.string
ensure
  $stdout = old_stdout
end


#----------------------------------------------------------------------------
# Feed stdin with a prepared string
#----------------------------------------------------------------------------

def feed_stdin( str, &block )
  old_stdin  = $stdin
  fake_stdin = StringIO.new str
  $stdin     = fake_stdin
  
  yield
ensure
  $stdin = old_stdin
end


describe Parser do

  before :all do
    @parser = Parser.new
  end

  describe "Emptyness" do
    it "should not be allowed" do
      expect { @parser.line_do }.to raise_error( ParserError )
    end
    it "should not be allowed" do
      expect { @parser.line_do nil }.to raise_error( ParserError )
    end
    
    it "should return 0 for an unused variable" do
      @parser.variables['A'].should eq 0
    end
  end
  
  describe ".do_assignment" do  # Each section checks that the previous variables are still set correctly
    it "should be able to set an integer" do
      @parser.line_do "A1=1\n"          # No spaces
      @parser.variables['A1'].should eq 1 
    end

    it "should be able to set a floating point value" do
      @parser.line_do "A2 =1.5"       # Space before
      @parser.variables['A2'].should eq 1.5 
      
      @parser.variables['A1'].should eq 1 
    end

    it "should be able to set a string" do
      @parser.line_do "A3= 'a string'" # Space after
      @parser.variables['A3'].should eq 'a string' 
      
      @parser.variables['A1'].should eq 1 
      @parser.variables['A2'].should eq 1.5 
    end

    it "should be able to set the value of another variable" do
      @parser.line_do "A4 = A2"       # Space both
      @parser.variables['A4'].should eq 1.5 
      @parser.variables['A4'].should eq @parser.variables['A2'] # Redundant, really
      
      @parser.variables['A1'].should eq 1 
      @parser.variables['A2'].should eq 1.5 
      @parser.variables['A3'].should eq 'a string' 
    end
    
    it "should use LET if it's present" do
      @parser.line_do "LET A5=5"      # No spaces
      @parser.variables['A5'].should eq 5 
      
      @parser.variables['A1'].should eq 1 
      @parser.variables['A2'].should eq 1.5 
      @parser.variables['A3'].should eq 'a string' 
      @parser.variables['A4'].should eq 1.5 
    end
  end
  
  describe ".do_print" do
    it "should work on its own to make a blank line" do
      output = capture_stdout do
        @parser.line_do "PRINT"
      end
      
      output.should eq "\n"
    end
  
    it "should allow printing of strings" do
      output = capture_stdout do
        @parser.line_do "PRINT 'hello world'\n" # UGH!
      end
      
      output.should eq "hello world\n"
    end
    
    it "should allow printing of integers" do
      output = capture_stdout do
        @parser.line_do "PRINT 1234"
      end
      
      output.should eq "1234\n"
    end

    it "should allow printing of floats" do
      output = capture_stdout do
        @parser.line_do "PRINT 123.456"
      end
      
      output.should eq "123.456\n"
    end    

    it "should allow printing of variables" do
      output = capture_stdout do
        @parser.line_do "PRINT A2"
      end
      
      output.should eq "1.5\n"
    end    

    it "should use ; to put two items together" do
      output = capture_stdout do
        @parser.line_do "PRINT A2;A1"
      end
      
      output.should eq "1.51\n"
    end    

    it "should use , to separate two items with a tab" do
      output = capture_stdout do
        @parser.line_do "PRINT A2,A1"
      end
      
      output.should eq "1.5\t1\n"
    end    

    it "should use ; to not end a line with a line ending" do
      output = capture_stdout do
        @parser.line_do "PRINT A2;"
      end
      
      output.should eq "1.5"
    end    
    
    it "should use , to end a line with a tab but no line ending" do
      output = capture_stdout do
        @parser.line_do "PRINT A2,"
      end
      
      output.should eq "1.5\t"
    end    
  end
  
  # These are only capturing stdout so that it doesn't pollute the results

  describe ".do_input" do
    it "should input a string" do
      capture_stdout do
        feed_stdin( "word\n" ) { @parser.line_do "INPUT A15" }
      end
      @parser.variables['A15'].should eq 'word'
    end
    
    it "should input an integer value" do
      capture_stdout do
        feed_stdin( "23\n" ) { @parser.line_do "INPUT A16" }
      end
      @parser.variables['A16'].should eq 23
    end

    it "should input a floating point value" do
      capture_stdout do
        feed_stdin( "23.67\n" ) { @parser.line_do "INPUT A17" }
      end
      @parser.variables['A17'].should eq 23.67
    end
    
  end
  
  describe ".do_conditional" do
    it "should do the action when the conditional is true" do
      output = capture_stdout do 
        @parser.line_do "IF A4 == 1.5 THEN PRINT 'it is'\n"
      end
      
      output.should eq "it is\n"
    end
    
    it "should not do the action when the conditional is false" do
      @parser.variables['A4'].should eq 1.5 
      @parser.line_do "IF A4 = 1.4 THEN A4 = 2"
      @parser.variables['A4'].should eq 1.5 
    end
  end
  
  describe "Malformed lines" do
    it "should raise an error for reserved word used as variable" do
      expect { @parser.line_do "LET INPUT = 1" }.to raise_error( ParserError )
    end

    it "should raise an error for INPUT without a variable" do
      expect { capture_stdout { @parser.line_do "INPUT 'Prompt';" } }.to raise_error( ParserError )
    end
  end
end