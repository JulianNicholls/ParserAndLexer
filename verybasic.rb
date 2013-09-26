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
    
    case statement[:token]
      when :eos, :REM then return   # Empty or comment line, ignore
      
      when :LET, :ident             # Assignment with LET optional
        do_assignment statement
        
      when :PRINT                   # Print
        do_print
        
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
    if statement[:token] == :LET
      ident = (expect [:ident])[:value]
    else
      ident = statement[:value]
    end
    
    expect [:assign]
    
    targ = expect [:integer, :float, :ident, :string]

    val = targ[:value]
    val = value_of( val ) if targ[:token] == :ident   # Another veriable
    
    @variables[ident] = val
  end
  
  
  def do_print
    last = nil
    item = expect [:string, :float, :integer, :ident, :separator, :eos]
    
    loop do
      case item[:token]
        when :eos then break;
        
        when :string, :float, :integer
          print item[:value]
          
        when :ident
          print value_of item[:value]
          
        when :separator
          print "\t" if item[:value] == ','
      end
      
      last = item
      item = expect [:string, :float, :integer, :ident, :separator, :eos]
    end
    
    puts unless last == { :token => :separator, :value => ';' }
  end
  
  def expect options
    this = @lexer.next
#    puts "expect( #{options.inspect} ) - #{this}"
    raise ParserError.new( "Unxexpected <#{this}> in #@line." ) unless options.include? this[:token]
    
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
    p.line_do "A7 = A8"   # Test default value
    p.line_do "PRINT \"String 1\""
    p.line_do "PRINT 'String 2'"
    p.line_do "PRINT A1, A5"
    p.line_do "PRINT A1; A6"
    p.line_do "PRINT 'A1 = ';A1, 'A2 = ';A6"
    p.line_do "PRINT 'This should all be ';"
    p.line_do "PRINT 'on the same line'"
  rescue ParserError => e
    puts "SYNTAX ERROR: #{e}"
  end
  
  puts p.inspect
end

