require_relative '../lexer'

describe 'Token' do
  let( :test1 ) { Token.new( :string, 'str' ) }
  subject { test1 }

  it { should eq Token.new( :string, 'str' ) }
end
