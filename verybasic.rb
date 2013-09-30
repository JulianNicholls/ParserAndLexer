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
  
  def expression
    value = term
    
  end
  
  
  def term
  
  end
  
  
  def factor
  
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
    
    targ = expect [:integer, :float, :ident, :string]

    val = targ.value
    val = value_of( val ) if targ.type == :ident   # Another variable
    
    @variables[ident] = val
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

