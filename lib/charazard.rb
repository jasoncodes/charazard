# coding: utf-8

require 'charazard/version'
require 'nokogiri'

module Charazard
  extend self

  CP1252_TABLE = {
    128 => 0x20AC, 130 => 0x201A, 131 => 0x0192, 132 => 0x201E, 133 => 0x2026, 134 => 0x2020, 135 => 0x2021,
    136 => 0x02C6, 137 => 0x2030, 138 => 0x0160, 139 => 0x2039, 140 => 0x0152, 142 => 0x017D, 145 => 0x2018,
    146 => 0x2019, 147 => 0x201C, 148 => 0x201D, 149 => 0x2022, 150 => 0x2013, 151 => 0x2014, 152 => 0x02DC,
    153 => 0x2122, 154 => 0x0161, 155 => 0x203A, 156 => 0x0153, 158 => 0x017E, 159 => 0x0178
  }

  UTF8_REGEX_PREFIX = /\A(
         [\x09\x0A\x0D\x20-\x7E]            # ASCII
       | [\xC2-\xDF][\x80-\xBF]             # non-overlong 2-byte
       |  \xE0[\xA0-\xBF][\x80-\xBF]        # excluding overlongs
       | [\xE1-\xEC\xEE][\x80-\xBF]{2}      # straight 3-byte
       |  \xEF[\x80-\xBE]{2}                #
       |  \xEF\xBF[\x80-\xBD]               # excluding U+fffe and U+ffff
       |  \xED[\x80-\x9F][\x80-\xBF]        # excluding surrogates
       |  \xF0[\x90-\xBF][\x80-\xBF]{2}     # planes 1-3
       | [\xF1-\xF3][\x80-\xBF]{3}          # planes 4-15
       |  \xF4[\x80-\x8F][\x80-\xBF]{2}     # plane 16
     )*/nx;

  def fix_invalid_unicode_literals(str)
    input = str.dup.force_encoding('ASCII-8BIT')
    input.gsub!(/\xef\xbb\xbf/n, '') # byte order marker
    input.gsub!(/\xef\xbf\xbd/n, '') # replacement character
    if input =~ /[\x80-\xFF]/n
      output = input.slice! 0, 0
      until input.empty?
        input =~ UTF8_REGEX_PREFIX or raise "UTF8 match failed"
        input = $'
        output << $&
        unless input.empty?
          byte = input.slice!(0,1).ord
          char = if CP1252_TABLE[byte]
            [CP1252_TABLE[byte]].pack 'U'
          else
            [byte].pack 'U'
          end
          output << char.force_encoding('ASCII-8BIT')
        end
      end
      output.force_encoding('UTF-8')
    else
      input.force_encoding('UTF-8')
    end
  end

  def strip_dom(str, keep_newline = false)
    str = str.gsub(/\v/, '') # remove vertical tabs
    str = str.gsub(/(?:\s|\xC2\xA0|\xEF\xBF\xBD)+/) do |match|
      if keep_newline && match =~ /(?:\r|\n)/
        "\n"
      else
        " "
      end
    end
    str = str.gsub(/[\x00-\x09\x0b-\x1f]/, '') # remove all chars < 0x20 except 0x10 (LF)
    str.strip
  end

  def fix_cp1252_entities(str)
    if str =~ /&#1[345][0-9];/
      CP1252_TABLE.each do |from,to|
        str = str.gsub "&##{from};", "&##{to};"
      end
    end
    str
  end

  def html_to_plain(str, keep_newline = true)
    str = fix_invalid_unicode_literals(str)

    if str.include? '<' or str.include? '&'
      str = fix_cp1252_entities(strip_dom(str))
      str.gsub!(/-<-/, '-&lt;-')
      doc = Nokogiri::HTML.fragment(str)
      doc.search('style,script').each(&:remove)
      doc.search('br').each do |br|
        br.replace(Nokogiri::XML::Text.new("\n", doc))
      end
      doc.search('p,div').each do |p|
        p.add_next_sibling(Nokogiri::XML::Text.new("\n", doc))
        p.add_previous_sibling(Nokogiri::XML::Text.new("\n", doc))
      end
      doc.search('ul,ol').each do |list|
        is_ordered = list.node_name.downcase == 'ol'
        start = list[:start] =~ /\A(\d+)\z/ ? $1.to_i : 1
        list.add_next_sibling Nokogiri::XML::Text.new("\n", doc)
        list.add_previous_sibling Nokogiri::XML::Text.new("\n", doc)
        list.css('li').each_with_index do |item,index|
          item_prefix_text = is_ordered ? "\n#{start+index}. " : "\n* "
          item.add_previous_sibling Nokogiri::XML::Text.new(item_prefix_text, doc)
        end
      end
      str = doc.inner_text
    end

    return strip_dom(str, keep_newline)
  end
end
