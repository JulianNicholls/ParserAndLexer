require './lexer'
require './program'

#----------------------------------------------------------------------------
# Parser
#----------------------------------------------------------------------------

class Parser
  ROUND_FUNCTIONS = {
    'ABS' => :abs,
    'CEIL' => :ceil,
    'FLOOR' => :floor,
    'ROUND' => :round
  }

  MATH_FUNCTIONS  = {
    'COS' => :cos,
    'SIN' => :sin,
    'TAN' => :tan,
    'ACOS' => :acos,
    'ASIN' => :asin,
    'ATAN' => :atan,
    'SQR' => :sqrt,
    'LOG' => :log,
    'LOG10' => :log10,
    'EXP' => :exp
  }

  STATEMENTS = {
    PRINT:  :do_print,
    INPUT:  :do_input,
    IF:     :do_conditional,
    FOR:    :do_for,
    GOTO:   :do_goto,
    GOSUB:  :do_gosub,
    READ:   :do_read
  }

  #--------------------------------------------------------------------------
  # Initialise, potentially with a different lexer than the default
  #--------------------------------------------------------------------------

  def initialize( opts = {} )
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

  def do_program( program_text )
    fail 'empty program specified' if program_text.nil? || program_text.empty?

    reset_variables

    @program    = Program.new program_text
    @orig_data  = @program.data
    @data       = @orig_data.dup

    while line_do( @program.next_line ) != :END
    end
  end

  #--------------------------------------------------------------------------
  # Do one line of BASIC
  #--------------------------------------------------------------------------

  def line_do( line = nil )
    unless line.nil?
      @line = line
      @lexer.from @line
    end

    fail 'No input specified' if @line.nil?

    statement = @lexer.next
    statement = @lexer.next if statement.type == :integer   # Line number, skip it

    if STATEMENTS.key?( statement.type )
      send( STATEMENTS[statement.type] )
    else
      case statement.type
      when :eos         then  return :eos    # May be expected, or not...

      when :REM, :DATA  then  return :eol # Empty, comment, or DATA line, so ignore

      when :LET, :ident then  do_assignment statement

      when :NEXT        then  return :NEXT

      when :RETURN      then  return :RETURN

      when :RESTORE     then  @data = @orig_data.dup

      when :STOP                    # Emergency stop, as I recall
        puts 'STOPped'
        return :END

      when :END         then  return  :END

      else                          # Ignore the not understood for now
        do_ignore
      end
    end

    :eol                          # Signify that the line has been handled
  end

  #--------------------------------------------------------------------------
  # Inspect
  #--------------------------------------------------------------------------

  def inspect
    "#<Parser @line=\"#{@line}\" #{@variables}>"
  end

  private

  #--------------------------------------------------------------------------
  # Temporary function to ignore lines not understood. There's not much to
  # finish now.
  #--------------------------------------------------------------------------

  def do_ignore
    puts "IGNORING <#{@line}> FOR NOW"
  end

  #--------------------------------------------------------------------------
  # Perform an assignment, optionally led in by LET.
  #--------------------------------------------------------------------------

  def do_assignment( leadin )
    ident = leadin.type == :LET ? (expect [:ident]).value : leadin.value

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
      case @lexer.peek_next_type
      when :eol, :eos           then  break
      when :string, :separator  then  item = @lexer.next

      else
        item = Token.new( :float, expression )
      end

      print_item item

      last = item
    end

    puts if last.nil? || last.type != :separator
  end

  #--------------------------------------------------------------------------
  # Allow input from the 'user'. The value is collected as numeric if the
  # input is all digits, with an optional decimal point.
  #--------------------------------------------------------------------------

  def do_input
    item, prompted = nil, false

    loop do
      item = expect [:string, :separator, :ident, :eos]
      break if item.type == :ident
      fail 'No variable specified for INPUT' if item.type == :eos

      prompted = true
      print_item item
    end

    print '? ' unless prompted
    val = $stdin.gets.chomp

    # All digits (and decimal point)
    val = (val.include?( '.' ) ? val.to_f : val.to_i) if val =~ /^(\d|\.)+$/

    @variables[item.value] = val
  end

  #--------------------------------------------------------------------------
  # Evaluate a conditional expression led in by IF and do the requested thing
  # if the condition is true.
  #--------------------------------------------------------------------------

  def do_conditional
    dc1 = inequality

    t = @lexer.peek_next_type

    while [:AND, :OR].include? t
      @lexer.skip

      # The rhs has to be evaluated here because of short-circuiting

      rhs = inequality

      case t
      when :AND   then dc1 = (dc1 && rhs)
      when :OR    then dc1 = (dc1 || rhs)
      end

      t = @lexer.peek_next_type
    end

    if dc1
      expect [:THEN]
      line_do
    end
  end

  #--------------------------------------------------------------------------
  # Do a FOR loop
  #--------------------------------------------------------------------------

  def do_for
    var, start, finish, step = collect_for_parms

    fail "STEP 0 IS INVALID in #{str}" if step == 0

    # Mark our place in the program because we'll need to return here at the
    # top of each loop

    place_line      = @program.cur_line
    @variables[var] = start

    # Top of the FOR loop

    loop do
      break if step < 0 && value_of( var ) < finish # Counting down
      break if step > 0 && value_of( var ) > finish # Counting up

      # Return to the top of the loop

      @program.cur_line = place_line

      # Go round the loop until we reach our NEXT

      ret = nil

      loop do
        ret  = line_do @program.next_line
        break if ret == :eos || ret == :NEXT || ret == :END
      end

      fail 'Missing NEXT' if ret == :eos
      break if ret == :END

      # We got NEXT, so go around again, as long as the (optional) variable
      # matches, if specified

      id = @lexer.next
      fail 'NEXT WITHOUT FOR ERROR' if id.type == :ident && id.value != var
      @variables[var] += step
    end
  end

  def collect_for_parms             # FOR ...
    var, step = expect( [:ident] ).value, 1  # var ...
    expect [:assign]                # = ...
    start  = expression             # 1 ...
    expect [:TO]                    # TO ...
    finish = expression             # 10 ...

    if @lexer.peek_next_type == :STEP  # STEP ...
      @lexer.skip
      step = expression     # 2
    end

    [var, start, finish, step]
  end

  #--------------------------------------------------------------------------
  # Do GOSUB
  #--------------------------------------------------------------------------

  def do_gosub
    place_line = @program.cur_line
    do_goto

    ret = nil

    loop do
      ret = line_do @program.next_line
      break if ret == :eos || ret == :RETURN || ret == :END
    end

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
    negate = false

    if @lexer.peek_next_type == :NOT
      @lexer.skip
      negate = true
    end

    lhside = expression
    cmp    = expect [:assign, :cmp_eq, :cmp_ne, :cmp_gt, :cmp_gte, :cmp_lt, :cmp_lte]
    rhside = expression

    truth = case cmp.type
            when  :cmp_eq, :assign then  (lhside == rhside)
            when  :cmp_ne     then  (lhside != rhside)
            when  :cmp_gt     then  (lhside > rhside)
            when  :cmp_gte    then  (lhside >= rhside)
            when  :cmp_lt     then  (lhside < rhside)
            when  :cmp_lte    then  (lhside <= rhside)
    end

    negate ? !truth : truth
  end

  #--------------------------------------------------------------------------
  # Evaluate an arithmetic expression, involving +, -, *, /, % (modulo),
  # ^ (exponentiation) and functions
  #--------------------------------------------------------------------------

  def expression
    part1 = factor

    t = @lexer.peek_next_type

    while [:plus, :minus].include? t
      @lexer.skip

      if t == :plus
        part1 += factor
      else
        part1 -= factor
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
      @lexer.skip

      case t
      when :multiply  then  factor1 *= term
      when :divide    then  factor1 /= term
      when :modulo    then  factor1 = factor1.modulo term
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
    t = expect [:br_open, :integer, :float, :ident]

    case t.type
    when :br_open           then  value = bracket_exp( t ) # Already collected '('
    when :integer, :float   then  value = t.value
    when :ident             then  value = function( t.value )
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
    expect [:br_open] if token.nil?
    value = expression
    expect [:br_close]

    value
  end

  #--------------------------------------------------------------------------
  # Perform a function, or return the value of a variable
  #--------------------------------------------------------------------------

  def function( name )
    rname = ROUND_FUNCTIONS[name]   # ABS, ROUND etc
    return bracket_exp.send( rname ) unless rname.nil?

    mname = MATH_FUNCTIONS[name]    # SIN, COS etc
    return Math.send( mname, bracket_exp ) unless mname.nil?

    value_of name
  end

  #--------------------------------------------------------------------------
  # Print one item (string, number, variable, separator)
  #--------------------------------------------------------------------------

  def print_item( item )
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

  def expect( options )
    n = @lexer.peek_next_type

    fail "Unexpected <#{n}> in #{@line}. (Valid: #{options.inspect})" \
      unless options.include? n

    @lexer.next
  end

  #--------------------------------------------------------------------------
  # Return the value of a stored variable.
  # Added a special variable (TI) which gives the current epoch.
  #--------------------------------------------------------------------------

  def value_of( name )
    return Time.now.to_f if name == 'TI'
    @variables[name]
  end
end

if __FILE__ == $PROGRAM_NAME && ARGV.count != 0
  p = Parser.new

  loaded = File.read( ARGV[0] )

  begin
    p.do_program loaded
  rescue ParserError => e
    puts "SYNTAX ERROR: #{e}"
  end

end
