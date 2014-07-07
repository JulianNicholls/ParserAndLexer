require_relative '../parser.rb'
require 'spec_helper.rb'

# Parser that allow access to its variables
class Parser
  attr_reader :variables
end

describe Parser do

  before :all do
    @parser = Parser.new
  end

  describe 'Emptyness' do
    it 'should not be allowed in .do_program' do
      expect { @parser.do_program '' }.to raise_error
    end

    it 'should not allow nil in .do_program' do
      expect { @parser.do_program nil }.to raise_error
    end

    it 'should return 0 for an unused variable' do
      expect( @parser.variables['A'] ).to eq 0
    end
  end

  # Each section checks that the previous variables are still set correctly

  describe '.do_assignment' do
    it 'should be able to set an integer' do
      @parser.line_do "A1=1\n"          # No spaces
      expect( @parser.variables['A1'] ).to eq 1
    end

    it 'should be able to set a floating point value' do
      @parser.line_do 'A2 =1.5'       # Space before
      expect( @parser.variables['A2'] ).to eq 1.5

      expect( @parser.variables['A1'] ).to eq 1
    end

    it 'should be able to set a string' do
      @parser.line_do "A3= 'a string'" # Space after
      expect( @parser.variables['A3'] ).to eq 'a string'

      expect( @parser.variables['A1'] ).to eq 1
      expect( @parser.variables['A2'] ).to eq 1.5
    end

    it 'should be able to set the value of another variable' do
      @parser.line_do 'A4 = A2'       # Space both
      expect( @parser.variables['A4'] ).to eq 1.5
      expect( @parser.variables['A4'] ).to eq @parser.variables['A2']

      expect( @parser.variables['A1'] ).to eq 1
      expect( @parser.variables['A2'] ).to eq 1.5
      expect( @parser.variables['A3'] ).to eq 'a string'
    end

    it 'should be able to set the value of an arithmetic expression' do
      @parser.line_do 'A6 = A2 * 10 + 5 - 3'
      expect( @parser.variables['A6'] ).to eq 17.0

      expect( @parser.variables['A1'] ).to eq 1
      expect( @parser.variables['A2'] ).to eq 1.5
      expect( @parser.variables['A3'] ).to eq 'a string'
      expect( @parser.variables['A4'] ).to eq 1.5
    end

    it 'should use LET if it is present' do
      @parser.line_do 'LET A5=5'      # No spaces
      expect( @parser.variables['A5'] ).to eq 5

      expect( @parser.variables['A1'] ).to eq 1
      expect( @parser.variables['A2'] ).to eq 1.5
      expect( @parser.variables['A3'] ).to eq 'a string'
      expect( @parser.variables['A4'] ).to eq 1.5
      expect( @parser.variables['A6'] ).to eq 17.0
    end
  end

  it 'should allow optional line numbers' do
    @parser.line_do '100 LET A7=7'
    expect( @parser.variables['A7'] ).to eq 7
  end

  describe '.do_print' do
    it 'should work on its own to make a blank line' do
      output = capture_stdout do
        @parser.line_do 'PRINT'
      end

      expect( output ).to eq "\n"
    end

    it 'should allow printing of strings' do
      output = capture_stdout do
        @parser.line_do "PRINT 'hello world'\n" # UGH!
      end

      expect( output ).to eq "hello world\n"
    end

    it 'should allow printing of integers' do
      output = capture_stdout do
        @parser.line_do 'PRINT 1234'
      end

      expect( output ).to eq "1234\n"
    end

    it 'should allow printing of floats' do
      output = capture_stdout do
        @parser.line_do 'PRINT 123.456'
      end

      expect( output ).to eq "123.456\n"
    end

    it 'should allow printing of variables' do
      output = capture_stdout do
        @parser.line_do 'PRINT A2'
      end

      expect( output ).to eq "1.5\n"
    end

    it 'should allow printing of expressions' do
      output = capture_stdout do
        @parser.line_do 'PRINT (123 + 456) * 10'
      end

      expect( output ).to eq "5790\n"
    end

    it 'should allow printing of a function' do
      output = capture_stdout do
        @parser.line_do 'PRINT SQR(2)'
      end

      expect( output ).to eq "1.4142135623730951\n"
    end

    describe 'Separators' do
      it 'should use ; to put two items together' do
        output = capture_stdout do
          @parser.line_do 'PRINT A2;A1'
        end

        expect( output ).to eq "1.51\n"   # 1.5 immediately followed by 1
      end

      it 'should use , to separate two items with a tab' do
        output = capture_stdout do
          @parser.line_do 'PRINT A2,A1'
        end

        expect( output ).to eq "1.5\t1\n"
      end

      it 'should use ; to not end a line with a line ending' do
        output = capture_stdout do
          @parser.line_do 'PRINT A2;'
        end

        expect( output ).to eq '1.5'
      end

      it 'should use , to end a line with a tab but no line ending' do
        output = capture_stdout do
          @parser.line_do 'PRINT A2,'
        end

        expect( output ).to eq "1.5\t"
      end
    end
  end

  # These are only capturing stdout so that it doesn't pollute the results

  describe '.do_input' do
    it 'should input a string' do
      capture_stdout do
        feed_stdin( "word\n" ) { @parser.line_do 'INPUT A15' }
      end

      expect( @parser.variables['A15'] ).to eq 'word'
    end

    it 'should input an integer value' do
      capture_stdout do
        feed_stdin( "23\n" ) { @parser.line_do 'INPUT A16' }
      end

      expect( @parser.variables['A16'] ).to eq 23
    end

    it 'should input a floating point value' do
      capture_stdout do
        feed_stdin( "23.67\n" ) { @parser.line_do 'INPUT A17' }
      end

      expect( @parser.variables['A17'] ).to eq 23.67
    end

    it 'should allow for a prompt' do
      capture_stdout do
        feed_stdin( "23\n" ) { @parser.line_do "INPUT 'Enter A16: ';A16" }
      end

      expect( @parser.variables['A16'] ).to eq 23
    end
  end

  describe '.do_conditional' do
    it 'should do the action when the conditional is true' do
      output = capture_stdout do
        @parser.line_do "IF A4 == 1.5 THEN PRINT 'it is'\n"
      end

      expect( output ).to eq "it is\n"
    end

    it 'should not do the action when the conditional is false' do
      @parser.line_do 'IF A4 = 1.4 THEN A4 = 2'
      expect( @parser.variables['A4'] ).to eq 1.5
    end

    it 'should accept 2-part AND' do
      @parser.variables['A_AND'] = 1
      @parser.line_do 'IF 1 <= 2 AND 2 <= 3 THEN A_AND = 2'   # Both true
      expect( @parser.variables['A_AND'] ).to eq 2

      @parser.line_do 'IF 1 <= 2 AND 3 <= 2 THEN A_AND = 3'   # Right false
      expect( @parser.variables['A_AND'] ).to eq 2

      @parser.line_do 'IF 1 >= 2 AND 2 <= 3 THEN A_AND = 4'   # Left false
      expect( @parser.variables['A_AND'] ).to eq 2

      @parser.line_do 'IF 1 >= 2 AND 2 >= 3 THEN A_AND = 5'   # Both false
      expect( @parser.variables['A_AND'] ).to eq 2
    end

    it 'should accept 3-part AND' do
      @parser.line_do 'IF 1 <= 2 AND 2 <= 3 AND 3 <= 4 THEN A_AND = 6'   # All true
      expect( @parser.variables['A_AND'] ).to eq 6
    end

    it 'should accept 2-part OR' do
      @parser.line_do 'IF 1 <= 2 OR 2 <= 3 THEN A_AND = 3'   # Both true
      expect( @parser.variables['A_AND'] ).to eq 3

      @parser.line_do 'IF 1 <= 2 OR 3 <= 2 THEN A_AND = 4'   # Right false
      expect( @parser.variables['A_AND'] ).to eq 4

      @parser.line_do 'IF 1 >= 2 OR 2 <= 3 THEN A_AND = 5'   # Left false
      expect( @parser.variables['A_AND'] ).to eq 5

      @parser.line_do 'IF 1 >= 2 OR 2 >= 3 THEN A_AND = 6'   # Both false
      expect( @parser.variables['A_AND'] ).to eq 5
    end

    it 'should accept 3-part OR' do
      @parser.line_do 'IF 1 >= 2 OR 2 >= 3 OR 3 <= 4 THEN A_AND = 9'   # Last true
      expect( @parser.variables['A_AND'] ).to eq 9
    end
  end

  describe 'Malformed lines' do
    it 'should raise an error for reserved word used as variable' do
      expect { @parser.line_do 'LET INPUT = 1' }.to raise_error
    end

    it 'should raise an error for INPUT without a variable' do
      expect do
        capture_stdout { @parser.line_do "INPUT 'Prompt';" }
      end.to raise_error
    end

    it 'should raise an error for GOTO with a line number that does not exist' do
      expect do
        @parser.do_program "GOTO 20\n30 REM OOPS\n"
      end.to raise_error
    end

    it 'should reject STEP 0 (unlikely, but there you go)' do
      expect { @parser.line_do 'FOR I = 1 TO 10 STEP 0' }.to raise_error
    end
  end
end
