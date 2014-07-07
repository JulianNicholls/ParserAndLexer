#----------------------------------------------------------------------------
# Token returned by lexer
#----------------------------------------------------------------------------
class Token
  attr_reader :type, :value

  def initialize( type, value = nil )
    @type, @value  = type, value
  end

  def to_s
    "<#{@type}: #{@value}>"
  end

  def ==( other )
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

  PATTERNS = {
    /\A['"]/            => :collect_string,
    /\A[\d\.]+/         => :collect_number,   # Must precede ident, \w includes \d
    /\A\w+/             => :collect_ident,
    /\A==?/             => :collect_equals,
    /\A[!<>]=?/         => :collect_compare,
    /\A[\+\-\*\/%\^]/   => :collect_operator,
    /\A[\r\n]+/         => :collect_eol,
    /\A[\(\)]/          => :collect_bracket,
    /\A[\[\]]/          => :collect_sqbracket,
    /\A:/               => :collect_colon,
    /\A[,;]/            => :collect_separator
  }

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

  #----------------------------------------------------------------------------
  # Initialise, potentially with a replaced set of reserved words
  #----------------------------------------------------------------------------

  def initialize( opts = {} )
    @reserved = opts[:reserved] || RESERVED
  end

  #----------------------------------------------------------------------------
  # Get string to work from, making sure that we have a copy of it rather than
  # the original, because we are going to do destructive things.
  #----------------------------------------------------------------------------

  def from( string )
    @str = string.dup
    self              # Allow chaining
  end

  #----------------------------------------------------------------------------
  # Return the next token, removing it from the string.
  #----------------------------------------------------------------------------

  def next
    ret = peek_next
    @str.slice! @last_re if ret.type != :eos

    ret
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

  def expect( options )
    n = peek_next_type

    fail "Unexpected <#{n}> in #{@str}. (Valid: #{options.inspect})" \
      unless options.include? n

    self.next
  end

  #----------------------------------------------------------------------------
  # Return the next token (or just its type) non-destructively
  #----------------------------------------------------------------------------

  def peek_next_type
    peek_next.type
  end

  def peek_next
    fail 'No string specified' if @str.nil?

    return Token.new( :eos ) if skip_space == :eos

    PATTERNS.each do |re, func|
      re.match( @str ) do |mat|
        @last_re = re           # This is what will be removed
        return send( func, mat )
      end
    end

    # No match, more or less impossible since an ident match will mop up
    # almost anything

    fail "Unrecognised: '#{@str}'"
  end

  private

  #----------------------------------------------------------------------------
  # Simply match a colon
  #----------------------------------------------------------------------------

  def collect_colon( _mat )
    Token.new :colon
  end

  #----------------------------------------------------------------------------
  # Match a set of CR and LF, returning a single token.
  #----------------------------------------------------------------------------

  def collect_eol( _mat )
    Token.new :eol
  end

  #----------------------------------------------------------------------------
  # Match a comparison operator: =, ==, !=, <, <=, >, >=
  #----------------------------------------------------------------------------

  def collect_compare( mat )
    Token.new CMPS[mat.to_s]
  end

  #----------------------------------------------------------------------------
  # Match a print separator: ; or ,
  #----------------------------------------------------------------------------

  def collect_separator( mat )
    Token.new( :separator, mat.to_s )
  end

  #----------------------------------------------------------------------------
  # Match an assignment or equality comparison: = or ==
  # Although = is assignment, it is accepted as equals in a comparison
  # expression
  #----------------------------------------------------------------------------

  def collect_equals( mat )
    Token.new( mat.to_s == '=' ? :assign : :cmp_eq )
  end

  #----------------------------------------------------------------------------
  # Match a bracket: ( or )
  #----------------------------------------------------------------------------

  def collect_bracket( mat )
    Token.new( mat.to_s == '(' ? :br_open : :br_close )
  end

  #----------------------------------------------------------------------------
  # Match a square bracket: [ or ]
  #----------------------------------------------------------------------------

  def collect_sqbracket( mat )      # Square bracket
    Token.new( mat.to_s == '[' ? :sqbr_open : :sqbr_close )
  end

  #----------------------------------------------------------------------------
  # Match an arithmetic operator, or a negative number because that is led-in
  # by a minus operator, of course.
  #----------------------------------------------------------------------------

  def collect_operator( mat )
    if mat.to_s == '-' && (peek =~ /\d/)
      re = /\A-[\d\.]+/
      mat2 = re.match @str
      @last_re = re
      return collect_number mat2
    end

    Token.new OPERATORS[mat.to_s]
  end

  #----------------------------------------------------------------------------
  # Match a number, either an integer or a floating-point value
  #----------------------------------------------------------------------------

  def collect_number( mat )
    str  = mat.to_s
    is_f = str.include? '.'

    # Throw a fit if there's more than one decimal point

    fail "Invalid number encountered: #{str}" if str =~ /.*\..*\./

    is_f ? Token.new( :float, str.to_f ) : Token.new( :integer, str.to_i )
  end

  #----------------------------------------------------------------------------
  # Match a variable identifier, upper and lower case, underscores and numbers
  #----------------------------------------------------------------------------

  def collect_ident( mat )
    str = mat.to_s

    @reserved.include?( str ) ? Token.new( str.to_sym ) : Token.new( :ident, str )
  end

  #----------------------------------------------------------------------------
  # Match a string delimited by either ' or ".
  #----------------------------------------------------------------------------

  def collect_string( mat )
    del  = mat.to_s
    re   = Regexp.new "#{del}([^#{del}]+)#{del}"
    mat2 = re.match @str

    fail "Unterminated string encountered: #{@str}" if mat2.nil?

    @last_re = re

    Token.new( :string, mat2[1] )
  end

  #----------------------------------------------------------------------------
  # Collect a list of comma separated values into an array
  #----------------------------------------------------------------------------

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
  # Skip spaces and tabs and return EOS if there's no more to be had.
  #----------------------------------------------------------------------------

  def skip_space
    @str.slice!( /\A[ \t]+/ );   # Not \s, because we want to capture EOL characters
    eos? ? :eos : :ok
  end

  #----------------------------------------------------------------------------
  # Peek at the character after the current one, so that we can see if there is
  # a digit following a minus sign, for example
  #----------------------------------------------------------------------------

  def peek
    @str[1]                     # Character after the one just matched
  end

  #----------------------------------------------------------------------------
  # Return whether the string is exhausted
  #----------------------------------------------------------------------------

  def eos?                      # Are we done with this string?
    @str.empty?
  end
end
