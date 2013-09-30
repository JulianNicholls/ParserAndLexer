#----------------------------------------------------------------------------
# Very basic BASIC parser.
#----------------------------------------------------------------------------

require './lexer'


#----------------------------------------------------------------------------
# Exception thrown for syntax errors.
#----------------------------------------------------------------------------

class ParserError < Exception
end


#----------------------------------------------------------------------------
# Parser
#----------------------------------------------------------------------------

class Parser
  
  attr_reader :variables
  
  #--------------------------------------------------------------------------
  # Initialise, potentially with a different lexer than the default
  #--------------------------------------------------------------------------

  def initialize opts = {}
    @line      = nil
    @lexer     = opts[:lexer] || Lexer.new
    @variables = Hash.new( 0 )
    
    @variables['PI'] = Math::PI
    @variables['E']  = Math::E
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
    
    case statement.type
      when :eos, :REM then return   # Empty or comment line, ignore
      
      when :LET, :ident             # Assignment with LET optional
        do_assignment statement
        
      when :PRINT                   # Print
        do_print
        
      when :INPUT                   # Input
        do_input
        
      when :IF                      # Conditional
        do_conditional
        
      else                          # Ignore the not understood for now
        do_ignore
    end
  end

  
  #--------------------------------------------------------------------------
  # Inspect
  #--------------------------------------------------------------------------

  def inspect
    ret = "#<Parser @line=\"#{@line}\" #@variables"
    
    ret + '>'
  end
  
private

  #--------------------------------------------------------------------------
  # Temporary function to ignore lines not understood, which is most of them
  # at the moment
  #--------------------------------------------------------------------------

  def do_ignore
    puts "IGNORING <#@line> FOR NOW";
  end
  
  
  #--------------------------------------------------------------------------
  # Perform an assignment, optionally led in by LET.
  #--------------------------------------------------------------------------

  def do_assignment statement
    if statement.type == :LET
      ident = (expect [:ident]).value
    else
      ident = statement.value
    end
    
    expect [:assign]

    if @lexer.peek_next.type == :string
      @variables[ident] = @lexer.next.value
    else
      @variables[ident] = expression
    end
  end
  
  
  #--------------------------------------------------------------------------
  # Do a PRINT
  #--------------------------------------------------------------------------

  def do_print
    last, item = nil, nil
    
    loop do
      item = expect [:string, :float, :integer, :ident, :separator, :eos, :eol]

      break if item.type == :eos || item.type == :eol
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
    item = nil
    
    loop do
      item = expect [:string, :separator, :ident, :eos]
      break if item.type == :ident
      raise ParserError.new( "No variable specified for INPUT" ) if item.type == :eos
      
      print_item item
    end
      
    print '? '
    value = gets.chomp
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
    else
      skip_to_end
    end
  end
  

  #--------------------------------------------------------------------------
  # Evaluate a comparison expression
  #--------------------------------------------------------------------------

  def inequality
    lhside = expression
    cmp    = expect [:assign, :cmp_eq, :cmp_ne, :cmp_gt, :cmp_gte, :cmp_lt, :cmp_lte]
    rhside = expression
    
    case cmp.type
      when  :cmp_eq, :assign then  reply = (lhside == rhside)
      when  :cmp_ne   then  reply = (lhside != rhside)
      when  :cmp_gt   then  reply = (lhside > rhside)
      when  :cmp_gte  then  reply = (lhside >= rhside)
      when  :cmp_lt   then  reply = (lhside < rhside)
      when  :cmp_lte  then  reply = (lhside <= rhside)
    end
    
    reply
  end

  #--------------------------------------------------------------------------
  # Evaluate an arithmetic expression, involving +, -, *, /, % (modulo)
  # To come: ^ for exponentiation
  #--------------------------------------------------------------------------

  def expression
    part1 = factor
    
    t = @lexer.peek_next
    
    while [:plus, :minus].include? t.type
      t     = @lexer.next
      part2 = factor
      
      if t.type == :plus
        part1 += part2
      else
        part1 -= part2
      end
      
      t = @lexer.peek_next
    end
    
    part1
  end
  
  
  #--------------------------------------------------------------------------
  # Evaluate a multiplicative expression
  #--------------------------------------------------------------------------

  def factor
    factor1 = term
    
    t = @lexer.peek_next
    
    while [:multiply, :divide, :modulo].include? t.type
      t       = @lexer.next
      factor2 = term
      
      case t.type
        when :multiply  then  factor1 *= factor2
        when :divide    then  factor1 /= factor2
        when :modulo    then  factor1 = factor1.modulo factor2
      end

      t = @lexer.peek_next
    end
    
    factor1
  end
  

  #--------------------------------------------------------------------------
  # Evaluate a single term (variable, number, bracketed expression) in an 
  # expression
  #--------------------------------------------------------------------------

  def term
    t = @lexer.next
    
    if t.type == :br_open
      value = expression
      
      expect [:br_close]
    elsif [:integer, :float].include? t.type
      value = t.value
    elsif t.type == :ident
      value = value_of( t.value )
    else
      raise ParserError.new( "Unexpected token in term: #{t}" )
    end
    
    value
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
  # Return the value of a stored variable
  #--------------------------------------------------------------------------

  def value_of name
    @variables[name]
  end

  #--------------------------------------------------------------------------
  # Skip to the end of the current line or string
  #--------------------------------------------------------------------------

  def skip_to_end
    while !([:eos, :eol].include? @lexer.next.type)
    end
  end
  
end


if __FILE__ == $0
  p = Parser.new

  begin
    p.line_do "LET A1 = 1"
    p.line_do "A5 = 5"
    p.line_do "A6 = 6"
    p.line_do 'INPUT "Value for A9";A9'
    p.line_do "A7 = A8"   # Test default value
    p.line_do 'PRINT'
    p.line_do 'PRINT "PI=";PI'
    p.line_do 'PRINT "E=";E'
    p.line_do 'PRINT "String 1"'
    p.line_do "PRINT 'String 2'"
    p.line_do "PRINT A1, A5"
    p.line_do "PRINT A1; A6"
    p.line_do "PRINT 'A1 = ';A1, 'A2 = ';A6, 'A9 = '; A9"
    p.line_do "PRINT 'This should all be ';"
    p.line_do "PRINT 'on the same line'"
    p.line_do "PRINT 'This word',"
    p.line_do "PRINT 'should have a tab after it'"
  rescue ParserError => e
    puts "SYNTAX ERROR: #{e}"
  end
  
  puts p.inspect
end

