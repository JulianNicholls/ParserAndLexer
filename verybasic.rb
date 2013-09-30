# verybasic

require './lexer'

class ParserError < Exception
end

class Parser
  
  attr_reader :variables
  
  def initialize opts = {}
    @line      = nil
    @variables = Hash.new( 0 )    # Unknown variables = 0
    @lexer     = opts[:lexer] || Lexer.new
  end
  
  def line_do line
    @line = line
    
    raise ParserError.new( "No input specified" ) if @line.nil?
    
    statement = @lexer.from( @line ).next
    
    case statement.type
      when :eos, :REM then return   # Empty or comment line, ignore
      
      when :LET, :ident             # Assignment with LET optional
        do_assignment statement
        
      when :PRINT                   # Print
        do_print
        
      when :INPUT                   # Input
        do_input
        
      else                          # Ignore the not understood for now
        do_ignore
    end
  end

  def inspect
    ret = "#<Parser @line=\"#{@line}\" #@variables"
    
    ret + '>'
  end
  
private

  def do_ignore
    puts "IGNORING <#@line> FOR NOW";
  end
  
  
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
  
  
  def do_print
    last, item = nil, nil
    
    loop do
      item = expect [:string, :float, :integer, :ident, :separator, :eos]

      break if item.type == :eos
      print_item item
      
      last = item
    end
    
    puts unless last && (last.type == :separator)
  end
  
  
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
    @variables[item.value] = value
  end

  
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
  
  
  def print_item item
    case item.type
      when :string, :float, :integer  then print item.value
      when :ident                     then print value_of( item.value )
      when :separator                 then print "\t" if item.value == ','
    end
  end
  

  def expect options
    this = @lexer.next
    
    raise ParserError.new( "Unxexpected <#{this}> in #@line." ) \
      unless options.include? this.type
    
    this
  end
  
  
  def value_of name
    @variables[name]
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

