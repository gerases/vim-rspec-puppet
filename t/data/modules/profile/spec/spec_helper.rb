require 'rspec-puppet'

RSpec.configure do |c|
  c.module_path = File.expand_path(File.dirname(__FILE__) + '../../..')
end
