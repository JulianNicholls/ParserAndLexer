class Program

  attr_accessor :cur_line
  
  #--------------------------------------------------------------------------
  # Initialise with a set of lines delimited with EOLs
  #--------------------------------------------------------------------------

  def initialize program
    lines   = program.dup
    line_re = /\A(.*)[\n\r]+/
    
    @lines, @num_lines  = [], 0
    
    begin
      line = line_re.match lines
      @lines << line[1]
      lines.slice! line_re
      @num_lines += 1
    end while !lines.empty?

    @cur_line = 0
    
  end
  
  
  #--------------------------------------------------------------------------
  # Get the next line from the program.
  #--------------------------------------------------------------------------

  def next
    return 'END' if @cur_line >= @num_lines
    
    line = @lines[@cur_line]
    
    @cur_line += 1
    
    line
  end

  
  #--------------------------------------------------------------------------
  # Return an array of DATA defined in the program
  #--------------------------------------------------------------------------

  def data
    data_items = []
    lexer = Lexer.new
    
    @lines.each do |line|
      lexer.from line
      first = lexer.next
      first = lexer.next if first.type == :integer  # Skip line number
      if first.type == :DATA
        data_items << lexer.collect_data
      end
    end
    
    data_items.flatten
  end
  
  #--------------------------------------------------------------------------
  # Perform a GOTO. Returns a ParserError if the requested line number is 
  # not found.
  #--------------------------------------------------------------------------

  def goto line_number 
    line_index = 0
    lexer = Lexer.new
    
    @lines.each do |line|
      lexer.from line
      first = lexer.next
      if first.type == :integer && first.value == line_number
        @cur_line = line_index
        return
      end
      line_index += 1
    end
    
    raise ParserError.new "LINE NUMBER #{line_number} not found" 
  end
  
 end