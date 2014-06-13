# -*- coding: utf-8 -*-

require 'test_helper'
require 'charazard/io'
require 'csv'

describe Charazard::IO do
  it 'converts mixed character encodings into valid UTF-8' do
    src = StringIO.new "Name,Character\nEm dash,\x97\r\nSmart quotes,\x93Quoted String\x94\r"
    dst = Charazard::IO.new(src)
    assert_equal "Name,Character\nEm dash,—\nSmart quotes,“Quoted String”\n", dst.read
  end
end
