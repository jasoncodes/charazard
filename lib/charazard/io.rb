require 'charazard'
require 'filter_io'

module Charazard
  class IO < FilterIO
    def initialize(io)
      super do |data, state|
        # fix invalid UTF-8 literals
        data = Charazard.fix_invalid_unicode_literals(data)

        # grab another chunk if the last character is a delimiter
        raise FilterIO::NeedMoreData if data =~ /[\r\n]\z/ && !state.eof?
        # normalise line endings to LF
        data = data.gsub /\r\n|\r|\n/, "\n"

        data
      end
    end
  end
end
