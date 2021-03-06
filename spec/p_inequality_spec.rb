require_relative '../parser.rb'

# Allow access to inequality for testing
class Parser
  public :inequality

  def feed_inequality(str)
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

  describe '.inequality' do
    it 'should evaluate = as equals' do
      @parser.feed_inequality '1 = 1'
      expect(@parser.inequality).to eq true

      @parser.feed_inequality '1 = A1'
      expect(@parser.inequality).to eq false

      @parser.feed_inequality 'A3 = 2'
      expect(@parser.inequality).to eq false
    end

    it 'should evaluate == as equals' do
      @parser.feed_inequality '1 == 1'
      expect(@parser.inequality).to eq true

      @parser.feed_inequality '1 == A1'
      expect(@parser.inequality).to eq false

      @parser.feed_inequality 'A2 == 3'
      expect(@parser.inequality).to eq false
    end

    it 'should evaluate != as not equals' do
      @parser.feed_inequality '1 != 1'
      expect(@parser.inequality).to eq false

      @parser.feed_inequality '1 != 2'
      expect(@parser.inequality).to eq true
    end

    it 'should evaluate > as greater than' do
      @parser.feed_inequality '2 > 1'
      expect(@parser.inequality).to eq true

      @parser.feed_inequality '2 > 2'
      expect(@parser.inequality).to eq false

      @parser.feed_inequality '1 > 2'
      expect(@parser.inequality).to eq false
    end

    it 'should evaluate >= as greater than or equal to' do
      @parser.feed_inequality '2 >= 1'
      expect(@parser.inequality).to eq true

      @parser.feed_inequality '2 >= 2'
      expect(@parser.inequality).to eq true

      @parser.feed_inequality '1 > 2'
      expect(@parser.inequality).to eq false
    end

    it 'should evaluate < as less than' do
      @parser.feed_inequality '1 < 2'
      expect(@parser.inequality).to eq true

      @parser.feed_inequality '2 < 2'
      expect(@parser.inequality).to eq false

      @parser.feed_inequality '2 < 1'
      expect(@parser.inequality).to eq false
    end

    it 'should evaluate <= as less than or equal to' do
      @parser.feed_inequality '1 <= 2'
      expect(@parser.inequality).to eq true

      @parser.feed_inequality '2 <= 2'
      expect(@parser.inequality).to eq true

      @parser.feed_inequality '2 <= 1'
      expect(@parser.inequality).to eq false
    end

    it 'should accept NOT' do
      @parser.feed_inequality 'NOT 2 < 1'           # False negated
      expect(@parser.inequality).to eq true

      @parser.feed_inequality 'NOT 1 < 2'           # True negated
      expect(@parser.inequality).to eq false
    end
  end
end
