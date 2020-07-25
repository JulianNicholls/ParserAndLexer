# Storage for a BASIC program
class Program
  attr_reader :cur_line

  #--------------------------------------------------------------------------
  # Initialise with a set of lines delimited with EOLs
  #--------------------------------------------------------------------------

  def initialize(program)
    lines   = program.dup
    line_re = /\A(.*)[\n\r]+/

    @lines      = []
    @num_lines  = @cur_line = 0

    until lines.empty?
      line = line_re.match lines
      @lines << line[1]
      lines.slice! line_re
      @num_lines += 1
    end
  end

  #--------------------------------------------------------------------------
  # Get the next line from the program.
  #--------------------------------------------------------------------------

  def next_line
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
      first = lexer.next_skip_line_number

      data_items << lexer.collect_data if first.type == :DATA
    end

    data_items.flatten
  end

  #--------------------------------------------------------------------------
  # Perform a GOTO. Returns a StandardError if the requested line number is
  # not found.
  #--------------------------------------------------------------------------

  def goto(line_number)
    lexer = Lexer.new

    @cur_line = @lines.find_index do |line|
      lexer.from(line).next == Token.new(:integer, line_number)
    end

    fail "LINE NUMBER #{line_number} not found" unless @cur_line
  end

  # RETURN from a GOSUB or return to the top of a for loop.
  def do_return(dest_line)
    @cur_line = dest_line
  end
end
