# Storage for a BASIC program
class Program
  attr_accessor :cur_line

  #--------------------------------------------------------------------------
  # Initialise with a set of lines delimited with EOLs
  #--------------------------------------------------------------------------

  def initialize(program)
    lines   = program.dup
    line_re = /\A(.*)[\n\r]+/

    @lines, @num_lines, @cur_line  = [], 0, 0

    loop do
      line = line_re.match lines
      @lines << line[1]
      lines.slice! line_re
      @num_lines += 1
      break if lines.empty?
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
      first = lexer.next
      first = lexer.next if first.type == :integer  # Skip line number

      data_items << lexer.collect_data if first.type == :DATA
    end

    data_items.flatten
  end

  #--------------------------------------------------------------------------
  # Perform a GOTO. Returns a ParserError if the requested line number is
  # not found.
  #--------------------------------------------------------------------------

  def goto(line_number)
    line_index = 0
    lexer = Lexer.new

    @lines.each do |line|
      lexer.from line
      first = lexer.next
      @cur_line = line_index
      return if first == Token.new(:integer, line_number)

      line_index += 1
    end

    fail "LINE NUMBER #{line_number} not found"
  end
end
