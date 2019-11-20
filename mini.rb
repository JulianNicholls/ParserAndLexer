require 'parslet'

class Mini < Parslet::Parser

  rule( :integer )    { match( '[0-9]' ).repeat( 1 ) >> space? }
  
  rule( :space )      { match( '\s' ).repeat 1 }
  rule( :space? )     { space.maybe }
  
  rule( :operator )   { match( '[+]' ) >> space? }
  
  rule( :sum )        { integer >> operator >> expression }
  rule( :expression ) { sum | integer }
  
  root :expression
  
end

def parse( str )
  mini = Mini.new
  
  mini.parse( str )
rescue Parslet::ParseFailed => failure
  puts failure.cause.ascii_tree
end

puts parse( "1 + 2+ 3" )
puts parse( "a + 2" )
