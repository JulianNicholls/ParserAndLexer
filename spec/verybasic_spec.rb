require_relative '../verybasic.rb'

def capture_stdout &block
  old_stdout  = $stdout
  fake_stdout = StringIO.new
  $stdout     = fake_stdout
  
  block.call
  
  fake_stdout.string
  
ensure
  $stdout = old_stdout
end

describe Parser do

  before :all do
    @parser = Parser.new
  end

  describe "Emptyness" do
    it "should not be allowed" do
      expect { @parser.line_do nil }.to raise_error( ParserError )
    end
    
    it "should return 0 for an unused variable" do
      @parser.variables['A'].should == 0
    end
  end
  
  describe "Assignment" do  # Each section checks that the previous variables are still set correctly
    it "should be able to set an integer" do
      @parser.line_do "A1=1"      # No spaces
      @parser.variables['A1'].should == 1 
    end

    it "should be able to set a floating point value" do
      @parser.line_do "A2 =1.5"   # Space before
      @parser.variables['A2'].should == 1.5 
      
      @parser.variables['A1'].should == 1 
    end

    it "should be able to set a string" do
      @parser.line_do "A3= 'a string'" # Space after
      @parser.variables['A3'].should == 'a string' 
      
      @parser.variables['A1'].should == 1 
      @parser.variables['A2'].should == 1.5 
    end

    it "should be able to set the value of another variable" do
      @parser.line_do "A4 = A2" # Space both
      @parser.variables['A4'].should == 1.5 
      @parser.variables['A4'].should == @parser.variables['A2'] # Redundant, really
      
      @parser.variables['A1'].should == 1 
      @parser.variables['A2'].should == 1.5 
      @parser.variables['A3'].should == 'a string' 
    end
    
    it "should use LET if it's present" do
      @parser.line_do "LET A5=5"      # No spaces
      @parser.variables['A5'].should == 5 
      
      @parser.variables['A1'].should == 1 
      @parser.variables['A2'].should == 1.5 
      @parser.variables['A3'].should == 'a string' 
      @parser.variables['A4'].should == 1.5 
    end
  end
  
  describe "PRINT" do
    it "should allow printing of strings" do
      output = capture_stdout do
        @parser.line_do "PRINT 'hello world'" # UGH!
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
end