#----------------------------------------------------------------------------
# Token returned by lexer
#----------------------------------------------------------------------------
class Token
  attr_reader :type, :value

  def initialize(type, value = nil)
    @type  = type
    @value = value
  end

  def to_s
    "<#{@type}: #{@value}>"
  end

  def ==(other)
    (type == other.type) && (value == other.value)
  end
end

#----------------------------------------------------------------------------
# Lexer capable of collecting the salient parts of BASIC by default.
# The list of reserved words is replaceable.
#
# Backtracking by one token is inevitable, e.g. during arithmetic expression
# evaluation, and there are two obvious ways to do that.
#
# 1. a function to return the next token destructively and a reversion
#    function to return it again.
#
# 2. The choice below, which is to have a way to peek at the next token
#    non-destructively.
#
#----------------------------------------------------------------------------
class Lexer
  RESERVED = %w(
    PRINT INPUT LET IF THEN FOR TO STEP NEXT END STOP REM GOTO GOSUB RETURN
    READ DATA RESTORE AND OR NOT
  )

  CMPS = {
    '!=' => :cmp_ne,
    '<'  => :cmp_lt,
    '<=' => :cmp_lte,
    '>'  => :cmp_gt,
    '>=' => :cmp_gte
  }

  OPERATORS = {
    '-' => :minus,
    '+' => :plus,
    '*' => :multiply,
    '/' => :divide,
    '%' => :modulo,
    '^' => :exponent
  }

  PATTERNS = {
    /\A['"]/            => :collect_string,
    /\A[\d\.]+/         => :collect_number,
    /\A==?/             => -> (mat) { Token.new(mat == '=' ? :assign : :cmp_eq) },
    /\A[!<>]=?/         => -> (mat) { Token.new CMPS[mat] },
    %r{\A[\+\-\*/%\^]}  => :collect_operator,
    /\A[\r\n]+/         => -> (_ma) { Token.new(:eol) },
    /\A[\(\)]/          => -> (mat) { Token.new(mat == '(' ? :br_open : :br_close) },
    /\A[\[\]]/          => -> (mat) { Token.new(mat == '[' ? :sqbr_open : :sqbr_close) },
    /\A:/               => -> (_ma) { Token.new(:colon) },
    /\A[,;]/            => -> (mat) { Token.new(:separator, mat) },

    /\A\w+/             => ->(mat) { @reserved.include?(mat) ? Token.new(mat.to_sym) : Token.new(:ident, mat) }
  }

  #----------------------------------------------------------------------------
  # Initialise, potentially with a replaced set of reserved words
  #----------------------------------------------------------------------------

  def initialize(opts = {})
    @reserved = opts[:reserved] || RESERVED
  end

  #----------------------------------------------------------------------------
  # Get string to work from, making sure that we have a copy of it rather than
  # the original, because we are going to do destructive things.
  #----------------------------------------------------------------------------

  def from(string)
    @str = string.dup
    self # Allow chaining
  end

  #----------------------------------------------------------------------------
  # Return the next token, removing it from the string.
  #----------------------------------------------------------------------------

  def next
    ret = peek_next
    @str.slice! @last_re if ret.type != :eos

    ret
  end

  # :reek:DuplicateMethodCall - next is not idempotent, by design
  def next_skip_line_number
    first = self.next
    first.type == :integer ? self.next : first
  end

  #----------------------------------------------------------------------------
  # Skip the next token, (peeked at already, most likely)
  #----------------------------------------------------------------------------

  def skip
    @str.slice! @last_re if peek_next_type != :eos
  end

  #----------------------------------------------------------------------------
  # Expect definite tokens
  #----------------------------------------------------------------------------

  def expect(options)
    type = peek_next_type

    fail "Unexpected <#{type}> in #{@str}. (Valid: #{options.inspect})" \
      unless options.include? type

    self.next
  end

  #----------------------------------------------------------------------------
  # Return the next token (or just its type) non-destructively
  #----------------------------------------------------------------------------

  def peek_next_type
    peek_next.type
  end

  # :reek:NestedIterators - Two is fine AFAIC
  def peek_next
    fail 'No string specified' unless @str

    return Token.new(:eos) if skip_space == :eos

    PATTERNS.each do |re, func|
      re.match(@str) do |mat|
        @last_re = re # This is what will be removed
        mat = mat.to_s
        return func.is_a?(Symbol) ? send(func, mat) : instance_exec(mat, &func)
      end
    end
  end

  private

  #----------------------------------------------------------------------------
  # Match an arithmetic operator, or a negative number because that is led-in
  # by a minus operator, of course.
  #----------------------------------------------------------------------------

  def collect_operator(mat)
    return collect_negative_number if mat == '-' && (@str[1] =~ /\d/)

    Token.new OPERATORS[mat]
  end

  #----------------------------------------------------------------------------
  # Match a number, either an integer or a floating-point value
  #----------------------------------------------------------------------------

  def collect_negative_number
    @last_re = /\A-[\d\.]+/
    collect_number(@last_re.match(@str).to_s)
  end

  # :reek:FeatureEnvy - str is just a string
  def collect_number(mat)
    is_f = mat.include? '.'

    # Throw a fit if there's more than one decimal point
    fail "Invalid number encountered: #{str}" if mat =~ /.*\..*\./

    is_f ? Token.new(:float, mat.to_f) : Token.new(:integer, mat.to_i)
  end

  #----------------------------------------------------------------------------
  # Match a string delimited by either ' or ".
  #----------------------------------------------------------------------------

  def collect_string(delim)
    @last_re  = /#{delim}([^#{delim}]+)#{delim}/
    content   = @last_re.match @str

    fail "Unterminated string encountered: #{@str}" unless content

    Token.new(:string, content[1])
  end

  #----------------------------------------------------------------------------
  # Collect a list of comma separated values into an array
  #----------------------------------------------------------------------------

  # :reek:DuplicateMethodCall - next is not idempotent, by design
  def collect_data
    result = []

    loop do
      next_entry = self.next
      break if next_entry.type == :eos

      result << next_entry.value
      comma = self.next
      break if comma.type == :eos
    end

    result
  end

  #----------------------------------------------------------------------------
  # Skip spaces and tabs, and return EOS if there's no more to be had.
  #----------------------------------------------------------------------------

  def skip_space
    @str.slice!(/\A[ \t]+/); # Not \s, we want to capture EOL characters
    @str.empty? ? :eos : :ok
  end
end
