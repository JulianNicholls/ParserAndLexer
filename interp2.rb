require 'pp'
require 'parslet'

class MiniP < Parslet::Parser

# Single character rules

  rule( :lparen )     { str( '(' ) >> space? }
  rule( :rparen )     { str( ')' ) >> space? }
  rule( :comma )      { str( ',' ) >> space? }

  rule( :space )      { match( '\s' ).repeat 1 }
  rule( :space? )     { space.maybe }

# Things
  
  rule( :integer )    { match( '[0-9]' ).repeat( 1 ).as( :int ) >> space? }
  rule( :identifier ) { match( '[a-z]' ).repeat 1 }
  rule( :operator )   { match( '[+\-*\/]' ) >> space? }

# Grammar parts
  
  rule( :sum )        { integer.as( :left ) >> operator.as( :op ) >> expression.as( :right ) }
  rule( :arglist )    { expression >> (comma >> expression).repeat }
  rule( :funccall )   { identifier.as( :funccall ) >> lparen >> arglist.as( :arglist ) >> rparen }
  
  rule( :expression ) { funccall | sum | integer }
  
  root :expression
  
end


class IntLit < Struct.new( :int )
  def eval; int.to_i; end
end

class Calculation < Struct.new( :op, :left, :right )
  def eval
    left.eval.send( op.to_s.rstrip.to_sym, right.eval )
  end
end

class FuncCall < Struct.new( :name, :args )
  def eval
    p args.map { |s| s.eval }
  end
end


class MiniT < Parslet::Transform
  rule( :int => simple( :int ) )            { IntLit.new( int ) }
  
  rule( :left  => simple( :left ),
        :right => simple( :right ),
        :op => simple( :op ) )              { Calculation.new( op, left, right ) }
        
  rule( :funccall => 'puts',
        :arglist => subtree( :arglist ) )   { FuncCall.new( 'puts', arglist ) }
end

parser  = MiniP.new
trans   = MiniT.new

ast = trans.apply parser.parse( 'puts( 1 + 2, 2 * 6, 12 / 3, 415 - 14)' )

ast.eval

