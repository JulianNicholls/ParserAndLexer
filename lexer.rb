class Lexer

    STRING      = 1
    INTEGER     = 2
    IDENT       = 3
    OPERATOR    = 4
    CHAR        = 5
    FLOAT       = 6
    
    BROPEN      = 8
    BRCLOSE     = 9
    EOL         = 10
    ASSIGN      = 11

    CMP_EQUAL   = 20
    CMP_LT      = 21
    CMP_LTE     = 22    # Must be CMP_LT+1
    CMP_GT      = 23
    CMP_GTE     = 24    # Must be CMP_GT+1
    CMP_NE      = 25
    
    LET         = 64          
    IF          = 65
    THEN        = 66
    FOR         = 67
    TO          = 68
    STEP        = 69
    NEXT        = 70
    PRINT       = 71
    
    EOS         = 99
    INVALID     = 128         # Or'ed in to indicate invalidity
    TOKEN_MASK  = 127         # Mask to remove INVALID
    
    RESERVED = {
      'PRINT'  => PRINT,
      'LET'    => LET,
      'IF'     => IF,
      'THEN'   => THEN,
      'FOR'    => FOR,
      'TO'     => TO,
      'STEP'   => STEP,
      'NEXT'   => NEXT
    }
    
    def initialize string = nil
      from string unless string.nil?
    end
    
    def from string
      @str    = string
      @cur    = 0
      @length = string.length
    end
    
    def next
      return { :token => EOS } if skip_space == :eos
      
      case @str[@cur]
        when "'", '"'
          return collect_string
          
        when 'A'..'Z', 'a'..'z', '_'
          return collect_ident
          
        when '0'..'9'
          return collect_number

        when '='
          return process_equal_sign

        when '!', '>', '<'
          return process_compare
          
        when '+', '-', '*', '/', '%'
          @cur += 1
          return { :token => OPERATOR, :value => @str[@cur-1] }
          
        when "\n", "\r"
          while @str[@cur] == "\n" || @str[@cur] == "\r"
            @cur += 1
          end
          return { :token => EOL }
          
        when '('
          @cur += 1
          return { :token => BROPEN  }

        when ')'
          @cur += 1
          return { :token => BRCLOSE  }
          
        else
          @cur += 1
          return { :token => CHAR, :value => @str[@cur-1] }
      end
    end

private

    def collect_number
      start_i = @cur
      type    = INTEGER
      ch      = @str[@cur]
      
      while !eos? && ((('0'..'9').include? ch) || ch == '.')
        type = FLOAT if ch == '.'
        @cur += 1
        ch   = @str[@cur]
      end
      
      str   = @str[start_i..@cur-1]
      value = (type == FLOAT) ? str.to_f : str.to_i
      
      { :token => type, :value => value }
    end
    
    def collect_string
      start_c = @str[@cur]
      end_i   = @str.index( start_c, @cur+1 )
      
      if end_i.nil?
        @cur = @length
        { :token => STRING | INVALID, :value => @str[(@cur+1)..@length-1] }
      else
        @cur    = end_i + 1
        { :token => STRING, :value => @str[(@cur+1)..(end_i-1)] }
      end
    end
    
    def collect_ident
      start_i = @cur
      ch      = @str[@cur]
      
      while !eos? && (/\w|\d|_/.match ch)
        @cur += 1
        ch   = @str[@cur]
      end

      value = @str[start_i..@cur-1]
      
      if RESERVED[value].nil?
        { :token => IDENT, :value => value }
      else
        { :token => RESERVED[value] }
      end
    end

    def process_equal_sign
      if @str[@cur+1] == '='  # Compare
        @cur += 2
        { :token => CMP_EQUAL }
      else
        @cur += 1
        { :token => ASSIGN }
      end
    end
    
    def process_compare
      ch  = @str[@cur]
      ch1 = @str[@cur+1]
      
      ret = { :token => CMP_GT } if ch == '>'
      ret = { :token => CMP_LT } if ch == '<'
      ret = { :token => CMP_NE } if ch == '!'
      
      if ret[:token] == CMP_LT || ret[:token] == CMP_GT
        if ch1 == '='
          ret[:token] += 1
          @cur += 1
        end
      elsif ret[:token] == CMP_NE
        if ch1 == '='
          @cur += 1
        else
          ret[:token] |= INVALID
        end
      end
      
      @cur += 1
      return ret
    end
    
    def skip_space
      while !eos? && (" \t".include? @str[@cur])
        @cur += 1
      end
      
      eos? ? :eos : :ok
    end
  
    def eos?
      @cur >= @length
    end
end

def render_loop lex
  cur = lex.next
  while cur[:token] != Lexer::EOS
    render cur
    cur = lex.next
  end
  
  puts
end


def render this
  print "  [#{this[:token] & Lexer::TOKEN_MASK}: #{this[:value]}#{' *** INVALID ***' if (this[:token] & Lexer::INVALID) != 0}]"
end


if $0 == __FILE__
  tests = [
    "varname = 12 + 25 / 89.1",
    "second=varname",
    "second==varname\n(2+3)",
    "'invalid",
    'str3 = "invalid',
    'PRINT A3',
    'LET str3="valid"',
    'FOR I = 1 TO 10',
    'FOR I = 1 TO 10 STEP 3',    
    'i == j < k <= l > m >= n != o'
  ]
  
  lex = Lexer.new
  
  tests.each do |t| 
    puts "|#{t}|"
    lex.from t
    render_loop lex
  end
end  
