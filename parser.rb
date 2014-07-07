require './lexer'
require './program'
require './expression'

#----------------------------------------------------------------------------
# Parser
#----------------------------------------------------------------------------
class Parser
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
    @line       = nil
    @lexer      = opts[:lexer] || Lexer.new
    @expression = ArithmeticExpression.new( self, @lexer )

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
      @lexer.from line
    end

    fail 'No input specified' if @line.nil?

    statement = @lexer.next
    statement = @lexer.next if statement.type == :integer   # Line number, skip it
    type      = statement.type

    if STATEMENTS.key?( type )
      send( STATEMENTS[type] )
    else
      case type
      when :eos, :NEXT, :RETURN, :END then return type

      when :REM, :DATA  then  return :eol # Empty, comment, or DATA line, so ignore

      when :LET, :ident then  do_assignment statement

      when :RESTORE     then  @data = @orig_data.dup

      when :STOP                    # Emergency stop, as I recall
        puts 'STOPped'
        return :END

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

  #--------------------------------------------------------------------------
  # Return the value of a stored variable.
  # Added a special variable (TI) which gives the current epoch.
  #--------------------------------------------------------------------------

  def value_of( name )
    return Time.now.to_f if name == 'TI'
    @variables[name]
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
                          @expression.evaluate
                        end
  end

  #--------------------------------------------------------------------------
  # Do a PRINT. Now recognises expressions, rather than expecting simple
  # values.
  #--------------------------------------------------------------------------

  def do_print
    last_item = nil

    loop do
      t = @lexer.peek_next_type
      break if t == :eol || t == :eos

      last_item = print_element( t )
    end

    puts if last_item.nil? || last_item.type != :separator
  end

  def print_element( type )
    if [:string, :separator].include? type
      item = @lexer.next
    else
      item = Token.new( :float, @expression.evaluate )
    end

    print_item item

    item
  end

  #--------------------------------------------------------------------------
  # Allow input from the 'user'. The value is collected as numeric if the
  # input is all digits, with an optional decimal point.
  #--------------------------------------------------------------------------

  def do_input
    prompted, item = input_prompt
    print '? ' unless prompted
    val = $stdin.gets.chomp

    # All digits (and decimal point)
    val = (val.include?( '.' ) ? val.to_f : val.to_i) if val =~ /^(\d|\.)+$/

    @variables[item.value] = val
  end

  def input_prompt
    prompted, item = false, nil

    loop do
      item = expect [:string, :separator, :ident, :eos]
      break if item.type == :ident
      fail 'No variable specified for INPUT' if item.type == :eos

      prompted = true
      print_item item
    end

    [prompted, item]
  end

  #--------------------------------------------------------------------------
  # Evaluate a conditional expression led in by IF and do the requested thing
  # if the condition is true.
  #--------------------------------------------------------------------------

  def do_conditional
    dc1 = inequality

    loop do
      t = @lexer.peek_next_type

      break unless [:AND, :OR].include? t
      @lexer.skip

      # The rhs has to be evaluated here because of short-circuiting

      rhs = inequality

      dc1 &&= rhs if t == :AND
      dc1 ||= rhs if t == :OR
    end

    return unless dc1

    expect [:THEN]
    line_do
  end

  #--------------------------------------------------------------------------
  # Do a FOR loop
  #--------------------------------------------------------------------------

  def do_for
    var, start, finish, step = collect_for_parms

    fail "STEP 0 IS INVALID in #{@str}" if step == 0

    # Mark our place in the program because we'll need to return here at the
    # top of each loop

    place_line      = @program.cur_line
    @variables[var] = start

    # Top of the FOR loop

    loop do
      break if step < 0 && value_of( var ) < finish # Counting down
      break if step > 0 && value_of( var ) > finish # Counting up

      # Go round the loop until we reach our NEXT or END, or fall out of
      # the bottom of the program, which is bad m'key.

      ret = do_for_loop( place_line )

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
    start  = @expression.evaluate   # 1 ...
    expect [:TO]                    # TO ...
    finish = @expression.evaluate   # 10 ...

    if @lexer.peek_next_type == :STEP  # STEP ...
      @lexer.skip
      step = @expression.evaluate     # 2
    end

    [var, start, finish, step]
  end

  def do_for_loop( place_line )
    # Return to the top of the loop

    @program.cur_line = place_line

    ret = nil

    loop do
      ret  = line_do @program.next_line
      break if ret == :eos || ret == :NEXT || ret == :END
    end

    fail 'Missing NEXT' if ret == :eos

    ret
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
    negate = @lexer.peek_next_type == :NOT

    @lexer.skip if negate

    cmp, lhside, rhside = collect_inequality

    truth = do_inequality( cmp, lhside, rhside )

    negate ? !truth : truth
  end

  def collect_inequality
    lhside = @expression.evaluate
    cmp    = expect [:assign, :cmp_eq, :cmp_ne, :cmp_gt, :cmp_gte, :cmp_lt, :cmp_lte]
    rhside = @expression.evaluate

    [cmp, lhside, rhside]
  end

  def do_inequality( cmp, lhside, rhside )
    case cmp.type
    when  :cmp_eq, :assign  then  (lhside == rhside)
    when  :cmp_ne           then  (lhside != rhside)
    when  :cmp_gt           then  (lhside > rhside)
    when  :cmp_gte          then  (lhside >= rhside)
    when  :cmp_lt           then  (lhside < rhside)
    when  :cmp_lte          then  (lhside <= rhside)
    end
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
    @lexer.expect( options )
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
