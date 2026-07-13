require_relative '../spec_helper.rb'

describe 'profile::my_define' do
  let(:title) { 'test' }

  it { is_expected.to compile }
end
