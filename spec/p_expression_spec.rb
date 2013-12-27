require_relative '../parser.rb'

# Allow access to expressions

class Parser
  public :expression

  def feed_expression( str )
    @line = str
    @lexer.from @line
  end
end

describe Parser do

  before :all do
    @parser = Parser.new
    @parser.line_do 'A1 = 10'
    @parser.line_do 'A2 = 20'
    @parser.line_do 'A3 = 30'
  end

  describe '.expression' do
    describe 'Simplest' do
      it 'should return an integer constant' do
        @parser.feed_expression '25'
        expect( @parser.expression ).to eq 25
      end

      it 'should return a float constant' do
        @parser.feed_expression '25.5'
        expect( @parser.expression ).to eq 25.5
      end

      it 'should simply return the value for a variable' do
        @parser.feed_expression 'A1'
        expect( @parser.expression ).to eq 10
      end
    end

    describe 'Simple operations' do
      it 'should work for addition' do
        @parser.feed_expression '2 + 5'
        expect( @parser.expression ).to eq 7
      end

      it 'should work for subtraction' do
        @parser.feed_expression '10 - 6'
        expect( @parser.expression ).to eq 4
      end

      it 'should work for multiplication' do
        @parser.feed_expression '2 * 5'
        expect( @parser.expression ).to eq 10
      end

      it 'should work for division' do
        @parser.feed_expression '20 / 5'
        expect( @parser.expression ).to eq 4
      end

      it 'should work for modulo' do
        @parser.feed_expression '15 % 7'
        expect( @parser.expression ).to eq 1
      end

      it 'should work for exponentiation' do
        @parser.feed_expression '2 ^ 10'
        expect( @parser.expression ).to eq 1024
      end

      it 'should work for a non-integer exponent' do
        @parser.feed_expression '9 ^ 0.5'
        expect( @parser.expression ).to eq 3
      end
    end

    it 'should accept expressions using variables' do
      @parser.feed_expression 'A1 + A2 +A3'
      expect( @parser.expression ).to eq 60

      @parser.feed_expression 'A3 * A1'
      expect( @parser.expression ).to eq 300

      @parser.feed_expression 'A3 / 3'
      expect( @parser.expression ).to eq 10

      @parser.feed_expression 'A1 + A2 - A3'
      expect( @parser.expression ).to eq 0

      @parser.feed_expression 'A1 - A3'
      expect( @parser.expression ).to eq( -20 )
    end

    describe 'Bracketed expressions' do
      it 'should accept simple ones' do
        @parser.feed_expression '(7+8)'
        expect( @parser.expression ).to eq 15

        @parser.feed_expression '(8 - 7)'
        expect( @parser.expression ).to eq 1

        @parser.feed_expression '(7*8)'
        expect( @parser.expression ).to eq 56

        @parser.feed_expression '(56 / 7.0)'
        expect( @parser.expression ).to eq 8
      end

      it 'should accept more elaborate ones' do
        @parser.feed_expression '10 *(7+8)'
        expect( @parser.expression ).to eq 150

        @parser.feed_expression 'A3* (A2+8)'
        expect( @parser.expression ).to eq 840
      end
    end

    describe 'Functions' do
      describe 'Trigonometric' do
        it 'should accept COS' do # Radians, don't forget
          @parser.feed_expression 'COS(1.047198)'   # 60 degress in Radians
          expect( @parser.expression ).to be_within( 0.000001 ).of( 0.5 )
        end

        it 'should accept SIN' do
          @parser.feed_expression 'SIN(0.523599)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 0.5 )
        end

        it 'should accept TAN' do
          @parser.feed_expression 'TAN(0.785398)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 1.0 )
        end

        it 'should accept ACOS' do
          @parser.feed_expression 'ACOS(0.5)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 1.047198 )
        end

        it 'should accept ASIN' do
          @parser.feed_expression 'ASIN(0.5)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 0.523599 )
        end

        it 'should accept ATAN' do
          @parser.feed_expression 'ATAN(1)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 0.785398 )
        end
      end

      describe 'Rounding' do
        it 'should accept ABS' do
          @parser.feed_expression 'ABS(2)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 2.0 )

          @parser.feed_expression 'ABS(-2)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 2.0 )
        end

        it 'should accept CEIL' do
          @parser.feed_expression 'CEIL(2.5)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 3.0 )
        end

        it 'should accept FLOOR' do
          @parser.feed_expression 'FLOOR(2.5)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 2.0 )
        end

        it 'should accept ROUND' do
          @parser.feed_expression 'ROUND(2.49)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 2.0 )

          @parser.feed_expression 'ROUND(2.51)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 3.0 )
        end
      end

      describe 'Logarithmic' do
        it 'should accept SQR' do
          @parser.feed_expression 'SQR(9)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 3.0 )
        end

        it 'should accept LOG' do
          @parser.feed_expression 'LOG(E)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 1.0 )
        end

        it 'should accept LOG10' do
          @parser.feed_expression 'LOG10(100)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( 2.0 )
        end

        it 'should accept EXP' do
          @parser.feed_expression 'EXP(1)'
          expect( @parser.expression ).to be_within( 0.000001 ).of( Math::E )
        end
      end
    end

    describe 'Precedence' do
      it 'should do functions first' do
        @parser.feed_expression 'COS(1) ^ 2'
        expect( @parser.expression ).to be_within( 0.000001 ).of( 0.291926 )

        @parser.feed_expression 'SIN(1) ^ 2'
        expect( @parser.expression ).to be_within( 0.000001 ).of( 0.708073 )

        @parser.feed_expression 'COS(1) ^ 2 + SIN(1) ^ 2' # cos2(x) + sin2(x) = 1
        expect( @parser.expression ).to be_within( 0.000001 ).of( 1.0 )
      end

      it 'should do exponentiation next' do
        @parser.feed_expression '2 + 2 ^ 5 * 10'
        expect( @parser.expression ).to eq 322
      end

      it 'should do *, /, and % before + and -' do
        @parser.feed_expression '2 + 3 * 5'
        expect( @parser.expression ).to eq 17   # NOT 25!

        @parser.feed_expression '3 * 2 + 3 * 5'
        expect( @parser.expression ).to eq 21   # NOT 75

        @parser.feed_expression '3 * 2 + 5 % 3'
        expect( @parser.expression ).to eq 8    # Not 2
      end

      it 'should allow bracketing to change it' do
        @parser.feed_expression '3 * (2 + 3) * 5'
        expect( @parser.expression ).to eq 75

        @parser.feed_expression '(2 ^ 10) ^ 2'
        expect( @parser.expression ).to eq 1_048_576
      end
    end
  end

  describe 'Exceptions' do
    it 'should be thrown for a missing right bracket' do
      @parser.feed_expression '10 *(7+8'
      expect { @parser.expression }.to raise_error
    end

    it 'should be thrown for a completely illegal expression' do
      @parser.feed_expression "10 + 'str'"
      expect { @parser.expression }.to raise_error
    end
  end

end
