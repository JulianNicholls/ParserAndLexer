class LexerError < Exception
end

class Lexer
 
  RESERVED = %w{PRINT INPUT LET IF THEN FOR TO STEP NEXT END STOP REM}
  
  PATTERNS = {
    /\A['"]/        => :collect_string,
    /\A[\d\.]+/     => :collect_number,   # Must precede ident, \w includes \d
    /\A\w+/         => :collect_ident,
    /\A==?/         => :collect_equals,
    /\A[!<>]=?/     => :collect_compare,
    /\A[\+\-\*\/%]/ => :collect_operator,
    /\A\r?\n\r?/    => :collect_eol,
    /\A[\(\)]/      => :collect_bracket,
    /\A[\[\]]/      => :collect_sqbracket,
    /\A:/           => :collect_colon,
    /,;/            => :collect_separator
  }
  
  def initialize opts = {}
    @reserved = opts[:reserved] || RESERVED
  end
  
  def from string
    @str = String.new string
    self              # Allow chaining
  end
  
  def next
    raise LexerError.new( "No string specified" ) if @str.nil?
    
    if skip_space != :eos
      PATTERNS.each do |re, func|
        re.match( @str ) do |mat|
          @str.slice! re
          return self.send( func, mat )
        end
      end
      
      ret  = { :token => :failed, :value => @str }
      @str = ''
      return ret
    end
    
    { :token => :eos }
  end

private

  def collect_colon mat           # Simple :
    { :token => :colon }
  end
  
  
  def collect_eol mat             # End of Line
    { :token => :eol }
  end
  
  
  def collect_compare mat         # Comparison operator
    { :token => :comparison, :value => mat.to_s }
  end

  
  def collect_operator mat        # Arithmetic operator, or negative value
    if mat.to_s == '-' && (/\d/.match( peek ) )
      re = /[\d\.]+/
      mat2 = re.match @str
      @str.slice! re
      return collect_number '-' + mat2.to_s
    end
    
    { :token => :operator, :value => mat.to_s }
  end

  
  def collect_separator mat        # PRINT separator, ; or ,
    { :token => :separator, :value => mat.to_s }
  end

  
  def collect_equals mat          # Assignment or comparison
    { :token => (mat.to_s == '=') ? :assign : :cmp_equal }
  end


  def collect_bracket mat         # Normal Bracket
    { :token => (mat.to_s == '(') ? :br_open : :br_close }
  end


  def collect_sqbracket mat       # Square bracket
    { :token => (mat.to_s == '[') ? :sqbr_open : :sqbr_close }
  end
  
  
  def collect_number mat          # Number, either integer or float
    str  = mat.to_s
    is_f = str.include? '.'
    { :token => is_f ? :float : :integer, :value => is_f ? str.to_f : str.to_i }
  end
  
  
  def collect_ident mat           # Identifier or reserved word
    str = mat.to_s
    if @reserved.include? str
      { :token => str.upcase.to_sym }
    else
      { :token => :ident, :value => str }
    end
  end

  
  def collect_string mat          # String delimited by ' or "
    re   = Regexp.new "([^#{mat.to_s}]+)#{mat.to_s}"
    mat2 = re.match( @str )
    
    if mat2.nil?   # Unterminated string
      ret  =  { :token => :string, :value => @str, :invalid => true }
      @str = ''
    else
      ret  =  { :token => :string, :value => mat2[1] }
      @str.slice! re
    end
    
    return ret
  end


  def skip_space                  # Skip spaces and tabs (not CR or LF)
    @str.slice!( /\A[ \t]/ );   # Not \s, because we want to capture EOL
    eos? ? :eos : :ok
  end
  
  def peek
    @str[0]
  end

  def eos?                        # Are we done with this string?
    @str.empty?
  end
end


if $0 == __FILE__
def render_loop lex
  cur = lex.next
  while cur[:token] != :eos
    render cur
    cur = lex.next
  end
  
  puts
end


def render this
  print "  [#{this[:token]}: #{this[:value]}#{' *** INVALID ***' if this[:invalid]}]"
end


  tests = [
    'LET str3="valid words"',
    "varname = 12 + 25 / 89.1",
    "second=varname",
    'str3 = "unterminated',
    'PRINT A3',
    'FOR I = 1 TO 10 STEP 3',
    'IF A3 > 1 THEN',
    'NEXT A3',
    'A[3] = 47',
    'A10 = -47',
    'j < k <= m >= n != o',
    "second==varname\n(2+3)",
  ]
  
  lex = Lexer.new
  
  # Try to provoke an exception
  
  begin
    fail = lex.next
  rescue LexerError => lexex
    puts "Expected exception: #{lexex}"
  end
  
  tests.each do |t| 
    puts "\n|#{t}|"
    lex.from t
    render_loop lex
  end
end  
