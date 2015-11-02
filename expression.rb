# Parser for arithmetic expressions
class ArithmeticExpression
  ROUND_FUNCS = {
    ABS:   :abs,
    CEIL:  :ceil,
    FLOOR: :floor,
    ROUND: :round
  }

  MATH_FUNCS = {
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
    @parent = parser
    @lexer  = lexer
  end

  #--------------------------------------------------------------------------
  # Evaluate an arithmetic expression, involving +, -, *, /, % (modulo),
  # ^ (exponentiation) and functions
  #--------------------------------------------------------------------------

  # :reek:DuplicateMethodCall - peek_next_type is not idempotent, by design
  def evaluate
    part = factor

    type = @lexer.peek_next_type

    while [:plus, :minus].include? type
      part = do_additive(part)

      type = @lexer.peek_next_type
    end

    part
  end

  def do_additive(value)
    @lexer.next.type == :plus ? value + factor : value - factor
  end

  #--------------------------------------------------------------------------
  # Evaluate a multiplicative expression
  #--------------------------------------------------------------------------

  # :reek:DuplicateMethodCall - peek_next_type is not idempotent, by design
  def factor
    left = term

    type = @lexer.peek_next_type

    while [:multiply, :divide, :modulo].include? type
      left = do_factor(left)

      type = @lexer.peek_next_type
    end

    left
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
    tok   = @lexer.expect [:br_open, :integer, :float, :ident]
    value = tok.value

    case tok.type
    when :br_open then  value = bracket_exp(tok) # Already collected '('
    # when :integer, :float, value is already set
    when :ident   then  value = function(value)
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

  # :reek:ControlParameter
  def bracket_exp(token = nil)
    @lexer.expect [:br_open] unless token
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
