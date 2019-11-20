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
  rule( :operator )   { match( '[+]' ) >> space? }

# Grammar parts
  
  rule( :sum )        { integer.as( :left ) >> operator.as( :op ) >> expression.as( :right ) }
  rule( :arglist )    { expression >> (comma >> expression).repeat }
  rule( :funccall )   { identifier.as( :funccall ) >> lparen >> arglist.as( :arglist ) >> rparen }
  
  rule( :expression ) { funccall | sum | integer }
  
  root :expression
  
end

pp MiniP.new.parse( "puts( 1+2+3, 45 )" )
