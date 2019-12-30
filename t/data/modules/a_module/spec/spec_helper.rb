require 'rspec-puppet'

RSpec.configure do |c|
  c.module_path = File.expand_path(File.dirname(__FILE__) + '../../..')
  puts c.module_path
  # c.module_path = File.expand_path('../../modules')
end
