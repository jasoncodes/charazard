require 'minitest/spec'
require 'minitest/autorun'

MiniTest::Spec::DSL.class_eval do
  alias_method :test, :it
end

require 'charazard'
