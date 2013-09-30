#----------------------------------------------------------------------------
# Exception thrown when the input is missing
#----------------------------------------------------------------------------

class LexerError < Exception
end


#----------------------------------------------------------------------------
# Token returned by lexer
#----------------------------------------------------------------------------

class Token

  attr_reader :type, :value
  
  def initialize( type, value = nil )
    @type, @value  = type, value
  end
  
  def to_s
    "<#@type: #@value>"
  end
  
  def == other
    (type == other.type) && (value == other.value)
  end
end


#----------------------------------------------------------------------------
# Lexer capable of collecting the salient parts of BASIC by default.
# The list of reserved words is replaceable
#----------------------------------------------------------------------------

class Lexer
 
  RESERVED = %w{PRINT INPUT LET IF THEN FOR TO STEP NEXT END STOP REM}
  
  PATTERNS = {
    /\A['"]/          => :collect_string,
    /\A[\d\.]+/       => :collect_number,   # Must precede ident, \w includes \d
    /\A\w+/           => :collect_ident,
    /\A==?/           => :collect_equals,
    /\A[!<>]=?/       => :collect_compare,
    /\A[\+\-\*\/%]/   => :collect_operator,
    /\A[\r\n][\n\r]*/ => :collect_eol,
    /\A[\(\)]/        => :collect_bracket,
    /\A[\[\]]/        => :collect_sqbracket,
    /\A:/             => :collect_colon,
    /\A[,;]/          => :collect_separator
  }
  
  def initialize opts = {}
    @reserved = opts[:reserved] || RESERVED
  end

  
  def from string
    @str = String.new string
    self              # Allow chaining
  end

  
  def next
    ret = peek_next
    @str.slice! @last_re
    
    ret
  end

  
  def peek_next
    raise LexerError.new( "No string specified" ) if @str.nil?
    
    if skip_space != :eos
      PATTERNS.each do |re, func|
        re.match( @str ) do |mat|
          @last_re = re
          return self.send( func, mat )
        end
      end
      
      ret  = Token.new( :failed, @str )
      @str = ''
      return ret
    end
    
    Token.new :eos
  end
  
private

  def collect_colon mat           # Simple :
    Token.new :colon
  end
  
  
  def collect_eol mat             # End of Line
    Token.new :eol
  end
  
  
  def collect_compare mat         # Comparison operator
    cmps = { '!=' => :cmp_ne, '<' => :cmp_lt, '<=' => :cmp_lte, '>' => :cmp_gt, '>=' => :cmp_gte }
    Token.new cmps[mat.to_s]
  end

  
  def collect_separator mat        # PRINT separator: ; or ,
    Token.new( :separator, mat.to_s )
  end

  
  def collect_equals mat          # Assignment or comparison
    Token.new( (mat.to_s == '=') ? :assign : :cmp_eq )
  end


  def collect_bracket mat         # Normal Bracket
    Token.new( (mat.to_s == '(') ? :br_open : :br_close )
  end


  def collect_sqbracket mat       # Square bracket
    Token.new( (mat.to_s == '[') ? :sqbr_open : :sqbr_close )
  end
  
  
  def collect_operator mat        # Arithmetic operator, or negative value
    if mat.to_s == '-' && (/\d/.match( peek ))
      re = /\A-[\d\.]+/
      mat2 = re.match @str
      @last_re = re
      return collect_number mat2.to_s
    end
    
    operators = { '-' => :minus, '+' => :plus, '*' => :multiply, '/' => :divide, '%' => :modulo }
    
    Token.new operators[mat.to_s]
  end

  
  def collect_number mat          # Number, either integer or float
    str  = mat.to_s
    is_f = str.include? '.'

    # Throw a fit if there's more than one decimal point
    
    raise LexerError.new( "Invalid number encountered: #{str}" ) if /.*\..*\./.match str

    Token.new( is_f ? :float : :integer, is_f ? str.to_f : str.to_i  )
  end
  
  
  def collect_ident mat           # Identifier or reserved word
    str = mat.to_s
    if @reserved.include? str
      Token.new( str.to_sym )
    else
      Token.new( :ident, str )
    end
  end

  
  def collect_string mat          # String delimited by ' or "
    del  = mat.to_s
    re   = Regexp.new "#{del}([^#{del}]+)#{del}"
    mat2 = re.match( @str )
    
    raise LexerError.new( "Unterminated string encountered: #{@str}" ) if mat2.nil?

    @last_re = re
    
    Token.new( :string, mat2[1] )
  end


  def skip_space                # Skip spaces and tabs (not CR or LF)
    @str.slice!( /\A[ \t]/ );   # Not \s, because we want to capture EOL
    eos? ? :eos : :ok
  end
  
  def peek
    @str[1]                     # Character after the one just matched
  end

  def eos?                      # Are we done with this string?
    @str.empty?
  end
end


if $0 == __FILE__
def render_loop lex
  cur = lex.next
  while cur.type != :eos
    print cur
    cur = lex.next
  end
  
  puts
end


  tests = [
    'LET str3="valid words"',
    "varname = 12 + 25 / 89.1",
    "second=varname",
    'PRINT A3',
    'FOR I = 1 TO 10 STEP 3',
    'IF A3 > 1 THEN',
    'NEXT A3',
    'A[3] = 47',
    'A10 = -47',
    'j < k <= m >= n != o',
    "second==varname\n(2+3)",
    'str3 = "unterminated',
  ]
  
  t = Token.new( :ident, 'new' )
  
  lex = Lexer.new
  
  # Try to provoke an exception
  
  begin
    fail = lex.next    
  rescue LexerError => lexex
    puts "Expected exception: #{lexex}"
  end

  begin
    tests.each do |t| 
      puts "\n|#{t}|"
      lex.from t
      render_loop lex
    end
  rescue LexerError => lexex
    puts "\nExpected exception: #{lexex}"
  end
  
end  
