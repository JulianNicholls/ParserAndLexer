# Parser for arithmetic expressions
class ArithmeticExpression
  ROUND_FUNCS = {
    ABS:   :abs,
    CEIL:  :ceil,
    FLOOR: :floor,
    ROUND: :round
  }

  MATH_FUNCS  = {
    COS:    :cos,
    SIN:    :sin,
    TAN:    :tan,
    ACOS:   :acos,
    ASIN:   :asin,
    ATAN:   :atan,
    SQR:    :sqrt,
    LOG:    :log,
    LOG10:  :log10,
    EXP:    :exp
  }

  #--------------------------------------------------------------------------
  # Initialise with the parent parser
  #--------------------------------------------------------------------------

  def initialize(parser, lexer)
    @parent, @lexer = parser, lexer
  end

  #--------------------------------------------------------------------------
  # Evaluate an arithmetic expression, involving +, -, *, /, % (modulo),
  # ^ (exponentiation) and functions
  #--------------------------------------------------------------------------

  def evaluate
    part1 = factor

    t = @lexer.peek_next_type

    while [:plus, :minus].include? t
      part1 = do_additive(part1)

      t = @lexer.peek_next_type
    end

    part1
  end

  def do_additive(value)
    if @lexer.next.type == :plus
      value + factor
    else
      value - factor
    end
  end

  #--------------------------------------------------------------------------
  # Evaluate a multiplicative expression
  #--------------------------------------------------------------------------

  def factor
    factor1 = term

    t = @lexer.peek_next_type

    while [:multiply, :divide, :modulo].include? t
      factor1 = do_factor(factor1)

      t = @lexer.peek_next_type
    end

    factor1
  end

  def do_factor(factor)
    case @lexer.next.type
    when :multiply  then  factor * term
    when :divide    then  factor / term
    when :modulo    then  factor.modulo term
    end
  end

  #--------------------------------------------------------------------------
  # Evaluate a single term: variable, number, bracketed expression, or
  # function in an expression. Exponentiation is also handled here.
  #--------------------------------------------------------------------------

  def term
    t = @lexer.expect [:br_open, :integer, :float, :ident]

    case t.type
    when :br_open           then  value = bracket_exp(t) # Already collected '('
    when :integer, :float   then  value = t.value
    when :ident             then  value = function(t.value)
    end

    value = do_powers(value) if @lexer.peek_next_type == :exponent

    value
  end

  def do_powers(value)
    @lexer.skip
    value**term
  end

  #--------------------------------------------------------------------------
  # Evaluate a bracketed expression. Broken out from term, so that
  # precedence is correct.
  #--------------------------------------------------------------------------

  def bracket_exp(token = nil)
    @lexer.expect [:br_open] if token.nil?
    value = evaluate
    @lexer.expect [:br_close]

    value
  end

  #--------------------------------------------------------------------------
  # Perform a function, or return the value of a variable
  #--------------------------------------------------------------------------

  def function(name)
    fname = name.upcase.to_sym
    return bracket_exp.send(ROUND_FUNCS[fname])      if ROUND_FUNCS.key? fname
    return Math.send(MATH_FUNCS[fname], bracket_exp) if MATH_FUNCS.key? fname

    @parent.value_of name
  end
end
