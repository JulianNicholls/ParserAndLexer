require './lexer'
require './program'


#----------------------------------------------------------------------------
# Exception thrown for syntax errors.
#----------------------------------------------------------------------------

class ParserError < Exception
end


#----------------------------------------------------------------------------
# Parser
#----------------------------------------------------------------------------

class Parser
  
  #--------------------------------------------------------------------------
  # Initialise, potentially with a different lexer than the default
  #--------------------------------------------------------------------------

  def initialize opts = {}
    @line      = nil
    @lexer     = opts[:lexer] || Lexer.new
    
    reset_variables
  end


  #--------------------------------------------------------------------------
  # Empty the variable hash, then put e and pi back in
  #--------------------------------------------------------------------------

  def reset_variables
    @variables = Hash.new( 0 )
    
    # Initialise pi and e
    
    @variables['PI'] = Math::PI
    @variables['E']  = Math::E  
  end

  
  #--------------------------------------------------------------------------
  # Do a whole program with lines separated by EOL characters
  #--------------------------------------------------------------------------
  
  def do_program program
    raise ParserError.new( "empty program specified" ) if program.nil? || program.empty?
    
    reset_variables
    
    @program    = Program.new program
    @orig_data  = @program.data
    @data       = @orig_data.dup
    
    while line_do( @program.next_line ) != :END
    end
  end

  
  #--------------------------------------------------------------------------
  # Do one line of BASIC
  #--------------------------------------------------------------------------

  def line_do line = nil
    unless line.nil?
      @line = line
      @lexer.from @line
    end

    raise ParserError.new( "No input specified" ) if @line.nil?
    
    statement = @lexer.next
    statement = @lexer.next if statement.type == :integer   # Line number, skip it
    
    case statement.type
      when :eos then return :eos    # May be expected, or not...
      
      when :REM, :DATA then return :eol # Empty, comment, or DATA line, so ignore
      
      when :LET, :ident             # Assignment with LET optional
        do_assignment statement
        
      when :PRINT                   # Print
        do_print
        
      when :INPUT                   # Input
        do_input
        
      when :IF                      # Conditional
        do_conditional
        
      when :FOR                     # FOR loop
        do_for
        
      when :NEXT                    # End of FOR loop
        return :NEXT
        
      when :GOTO                    # GOTO <LineNumber>
        do_goto
        
      when :GOSUB                   # GOSUB <LineNumber>
        do_gosub
        
      when :RETURN                  # RETURN from subroutine
        return :RETURN
        
      when :READ                    # READ Data
        do_read
        
      when :RESTORE                 # RESTORE
        @data = @orig_data.dup
        
      when :STOP                    # Emergency stop, as I recall
        puts "STOPped"
        return :END
        
      when :END                     # Graceful end
        return  :END
        
      else                          # Ignore the not understood for now
        do_ignore
    end
    
    return :eol                     # Signify that the line has been handled
  end

  
  #--------------------------------------------------------------------------
  # Inspect
  #--------------------------------------------------------------------------

  def inspect
    "#<Parser @line=\"#{@line}\" #@variables>"
  end
  
  
private

  #--------------------------------------------------------------------------
  # Temporary function to ignore lines not understood. There's not much to
  # finish now.
  #--------------------------------------------------------------------------

  def do_ignore
    puts "IGNORING <#@line> FOR NOW";
  end
  
  
  #--------------------------------------------------------------------------
  # Perform an assignment, optionally led in by LET.
  #--------------------------------------------------------------------------

  def do_assignment leadin
    ident = (leadin.type == :LET) ? (expect [:ident]).value : leadin.value
    
    expect [:assign]

    @variables[ident] = if @lexer.peek_next_type == :string
        @lexer.next.value
      else
        expression
      end
  end
  
  
  #--------------------------------------------------------------------------
  # Do a PRINT. Now recognises expressions, rather than expecting simple 
  # values.
  #--------------------------------------------------------------------------

  def do_print
    last, item = nil, nil
    
    loop do
      item = @lexer.peek_next_type
      
      case item
        when :eol, :eos           then  break
        when :string, :separator  then  item = @lexer.next
          
        else
          item = Token.new( :float, expression )
      end    

      print_item item
      
      last = item
    end
    
    puts unless last && (last.type == :separator)
  end
  
  
  #--------------------------------------------------------------------------
  # Allow input from the 'user'. The value is collected as numeric if the 
  # input is all digits, with an optional decimal point.
  #--------------------------------------------------------------------------

  def do_input
    item      = nil
    prompted  = false
    
    loop do
      item = expect [:string, :separator, :ident, :eos]
      break if item.type == :ident
      raise ParserError.new( "No variable specified for INPUT" ) if item.type == :eos
      
      prompted = true
      print_item item
    end
      
    print '? ' unless prompted
    value = $stdin.gets.chomp
    
    if value =~ /^[\d\.]+$/  # All digits
      value = (value.include? '.') ? value.to_f : value.to_i
    end
    
    @variables[item.value] = value
  end

  
  #--------------------------------------------------------------------------
  # Evaluate a conditional expression led in by IF and do the requested thing 
  # if the condition is true.
  #--------------------------------------------------------------------------

  def do_conditional
    if inequality
      expect [:THEN]
      line_do
    end
  end
  
  
  #--------------------------------------------------------------------------
  # Do a FOR loop
  #--------------------------------------------------------------------------

  def do_for                        # FOR ...
    var = expect( [:ident] ).value  # var ...
    expect [:assign]                # = ...
    start  = expression             # 1 ...
    expect [:TO]                    # TO ...
    finish = expression             # 10 ...
    step   = 1
    
    if @lexer.peek_next_type == :STEP  # STEP ...
      @lexer.skip
      step = expression     # 2
    end

    # Mark our place in the program because we'll need to return here at the 
    # top of each loop
    
    place_line      = @program.cur_line
    @variables[var] = start
    
    # Top of the FOR loop
    
    loop do
      if step < 0   # Counting down
        break if value_of( var ) < finish
      else
        break if value_of( var ) > finish
      end
      
      # Return to the top of the loop
      
      @program.cur_line = place_line
      
      ret = nil
      
      # Go round the loop until we reach our NEXT
      
      begin
        ret  = line_do @program.next_line
      end while ret != :eos && ret != :NEXT && ret != :END
      
      raise ParserError.new( "Missing NEXT" ) if ret == :eos
      break if ret == :END
      
      # We got NEXT, so go around again, as long as the (optional) variable
      # matches, if specified
      
      id = @lexer.next
      raise ParserError.new( "NEXT WITHOUT FOR ERROR" ) if id.type == :ident && id.value != var
      @variables[var] += step
    end
  end

  
  #--------------------------------------------------------------------------
  # Do GOSUB
  #--------------------------------------------------------------------------
  
  def do_gosub
    place_line = @program.cur_line
    do_goto
    
    begin
      ret = line_do @program.next_line
    end while ret != :eos && ret != :RETURN && ret != :END
    
    @program.cur_line = place_line if ret == :RETURN
  end
  
  
  #--------------------------------------------------------------------------
  # Do GOTO
  #--------------------------------------------------------------------------

  def do_goto
    line = expect [:integer]
    @program.goto line.value
  end

  
  #--------------------------------------------------------------------------
  # Do READ
  #--------------------------------------------------------------------------
  
  def do_read
    var = expect [:ident]
    
    @variables[var.value] = @data.shift
  end
  
  #--------------------------------------------------------------------------
  # Evaluate a comparison expression, with a single = allowed for equality
  #--------------------------------------------------------------------------

  def inequality
    lhside = expression
    cmp    = expect [:assign, :cmp_eq, :cmp_ne, :cmp_gt, :cmp_gte, :cmp_lt, :cmp_lte]
    rhside = expression
    
    case cmp.type
      when  :cmp_eq, :assign then  (lhside == rhside)
      when  :cmp_ne   then  (lhside != rhside)
      when  :cmp_gt   then  (lhside > rhside)
      when  :cmp_gte  then  (lhside >= rhside)
      when  :cmp_lt   then  (lhside < rhside)
      when  :cmp_lte  then  (lhside <= rhside)
    end
  end
  

  #--------------------------------------------------------------------------
  # Evaluate an arithmetic expression, involving +, -, *, /, % (modulo), 
  # ^ (exponentiation) and functions
  #--------------------------------------------------------------------------

  def expression
    part1 = factor
    
    t = @lexer.peek_next_type
    
    while [:plus, :minus].include? t
      t     = @lexer.next
      part2 = factor
      
      if t.type == :plus
        part1 += part2
      else
        part1 -= part2
      end
      
      t = @lexer.peek_next_type
    end
    
    part1
  end
  
  
  #--------------------------------------------------------------------------
  # Evaluate a multiplicative expression
  #--------------------------------------------------------------------------

  def factor
    factor1 = term
    
    t = @lexer.peek_next_type
    
    while [:multiply, :divide, :modulo].include? t
      t       = @lexer.next
      factor2 = term
      
      case t.type
        when :multiply  then  factor1 *= factor2
        when :divide    then  factor1 /= factor2
        when :modulo    then  factor1 = factor1.modulo factor2
      end

      t = @lexer.peek_next_type
    end
    
    factor1
  end
  

  #--------------------------------------------------------------------------
  # Evaluate a single term: variable, number, bracketed expression, or 
  # function in an expression. Exponentiation is also handled here.
  #--------------------------------------------------------------------------

  def term 
    t = @lexer.next
  
    case t.type
      when :br_open
        value = bracket_exp t     # We have already collected the '('
        
      when :integer, :float   then  value = t.value
      when :ident             then  value = function t.value
        
      else
        raise ParserError.new( "Unexpected token in term: #{t}" )
    end
    
    # Take care of power expressions here. 

    if @lexer.peek_next_type == :exponent
      @lexer.skip
      value **= term
    end
    
    value
  end
  
  
  #--------------------------------------------------------------------------
  # Evaluate a bracketed expression. Broken out from term, so that 
  # precedence is correct.
  #--------------------------------------------------------------------------

  def bracket_exp( token = nil )
    expect [:br_open] unless token
    value = expression
    expect [:br_close]

    value
  end

  #--------------------------------------------------------------------------
  # Perform a function, or return the value of a variable
  #--------------------------------------------------------------------------

  def function name
    case name
      when  'COS'   then  Math::cos( bracket_exp )
      when  'SIN'   then  Math::sin( bracket_exp )
      when  'TAN'   then  Math::tan( bracket_exp )
    
      when  'ACOS'  then  Math::acos( bracket_exp )
      when  'ASIN'  then  Math::asin( bracket_exp )
      when  'ATAN'  then  Math::atan( bracket_exp )
    
      when  'ABS'   then  bracket_exp.abs
      when  'CEIL'  then  bracket_exp.ceil
      when  'FLOOR' then  bracket_exp.floor
      when  'ROUND' then  bracket_exp.round

      when  'SQR'   then  Math::sqrt( bracket_exp )
      
      when  'LOG'   then  Math::log( bracket_exp )
      when  'LOG10' then  Math::log10( bracket_exp )
      when  'EXP'   then  Math::exp( bracket_exp )
      
      else
        value_of name
    end
  end
  
  
  
  #--------------------------------------------------------------------------
  # Print one item (string, number, variable, separator)
  #--------------------------------------------------------------------------

  def print_item item
    case item.type
      when :string, :float, :integer  then print item.value
      when :ident                     then print value_of( item.value )
      when :separator                 then print "\t" if item.value == ','
    end
  end
  

  #--------------------------------------------------------------------------
  # Read the next token and check that it is one of the expected ones, 
  # throwing an exception if not
  #--------------------------------------------------------------------------

  def expect options
    this = @lexer.next
    
    raise ParserError.new( "Unxexpected <#{this}> in #@line." ) \
      unless options.include? this.type
    
    this
  end
  
  
  #--------------------------------------------------------------------------
  # Return the value of a stored variable.
  # Added a special variable (TI) which gives the current epoch.
  #--------------------------------------------------------------------------

  def value_of name
    return Time.now.to_f if name == "TI"
    @variables[name]
  end
  
end


if __FILE__ == $0 && ARGV.count != 0
  p = Parser.new
  
  loaded = File.read( ARGV[0] )
  
  begin
    p.do_program loaded
  rescue ParserError => e
    puts "SYNTAX ERROR: #{e}"
  end  
  
end
