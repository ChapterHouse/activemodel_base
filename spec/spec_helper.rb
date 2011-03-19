require 'nested_logger'
require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'active_model_base'

module CustomMatchers
  def be_kind_of(klass)
    simple_matcher("kind of #{klass.name}") { |actual| actual.is_a?(klass) }
  end
end

RSpec.configure do |config|
  config.include CustomMatchers
end
