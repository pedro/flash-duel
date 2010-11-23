require "rspec/core"
require "rspec/expectations"

$:.unshift "#{File.dirname(__FILE__)}/../lib/flash_duel"
require "bot"
require "board"
require "engine"

RSpec.configure do |c|
  c.run_all_when_everything_filtered = true
  c.filter_run :focused => true
  c.alias_example_to :fit, :focused => true
  c.color_enabled = true
end
