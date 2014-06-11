# -*- coding: utf-8 -*-

require 'test_helper'

describe Charazard do
  describe 'fix_invalid_unicode_literals' do
    test "Test ISO-8859-1 literal conversion is idempotent" do
      assert_equal Charazard.html_to_plain("&trade; &copy; &reg;"), Charazard.fix_invalid_unicode_literals(Charazard.fix_invalid_unicode_literals("\231 \251 \256"))
    end

    test "ISO-8859-1 characters within words" do
      assert_equal "M\xc3\xa9nage \xc3\xa0 Trois for", Charazard.fix_invalid_unicode_literals("M\xe9nage \xe0 Trois for")
    end

    test "should fix literals in ASCII-8BIT without breaking correct UTF-8" do
      input = "r\xc3\xa9sum\xe9"
      input.force_encoding 'ASCII-8BIT'
      expected = "r\xc3\xa9sum\xc3\xa9"
      output = Charazard.fix_invalid_unicode_literals(input)
      assert_equal expected, output
    end

    test "replacement character (U+FFFD, UTF-8 EF BF BD) as invalid literal" do
      assert_equal "foo bar", Charazard.fix_invalid_unicode_literals("foo \xef\xbf\xbdbar")
    end

    test "byte order marker (U+FEFF, UTF-8 EF BB BF) as invalid literal" do
      assert_equal "foo bar", Charazard.fix_invalid_unicode_literals("foo \xef\xbb\xbfbar")
    end
  end

  describe 'strip_dom' do
    test "whitespace normalisation removing newlines" do
      assert_equal "foo bar", Charazard.strip_dom("  foo \n\t\tbar  \n  ")
    end

    test "whitespace normalisation keeping newlines" do
      assert_equal "foo\nbar", Charazard.strip_dom("  foo \n\t\tbar  \n  ", true)
    end

    test "newline preservation with multiple newlines together" do
      assert_equal "foo\nbar\nbaz", Charazard.strip_dom("foo\n\n\n\nbar\t\n\t\n\tbaz", true)
    end

    test "non-breaking space (UTF-8 C2 A0)" do
      assert_equal "foo bar", Charazard.strip_dom("foo\xc2\xa0bar")
    end

    test "replacement character (U+FFFD, UTF-8 EF BF BD)" do
      assert_equal "foo bar", Charazard.strip_dom("foo\xef\xbf\xbdbar")
    end

    test "CR in newline removal" do
      assert_equal "foo bar", Charazard.strip_dom("foo\rbar", false)
    end

    test "CR in newline preservation" do
      assert_equal "foo\nbar", Charazard.strip_dom("foo\rbar", true)
    end

    test "invalid Unicode code points below 0x20" do
      assert_equal "foobar", Charazard.strip_dom("foo\006bar")
      assert_equal "foobar\nbaz", Charazard.strip_dom("foo\006bar\n  baz", true)
      assert_equal "shes", Charazard.strip_dom("\x73\x68\x65\x1a\x73")
    end
  end

  describe 'html_to_plain' do
    test "html basic entities" do
      assert_equal "foo & \"bar\" <baz>", Charazard.html_to_plain("foo &amp; &quot;bar\" &lt;baz&gt;")
      assert_equal "foo\xc2\xae bar \xe2\x82\xac123!", Charazard.html_to_plain("foo&reg; bar &euro;12&#51;&#33;")
    end

    test "html basic pass through" do
      assert_equal "foo bar", Charazard.html_to_plain("foo bar")
    end

    test "html basic whitespace" do
      assert_equal "foo bar baz. Hello world. 1 2 3.", Charazard.html_to_plain("foo&nbsp;bar baz.&nbsp; Hello world.  1 2 3.")
    end

    test "html basic elements" do
      assert_equal "This is a test.", Charazard.html_to_plain("<strong>This</strong> <em>is <span style='text-decoration: underline'>a</span></em> <a href='http://www.example.com/' title=\"Testing\">test</a>.")
    end

    test "html block entities" do
      assert_equal "Foo\nBar\nabc\ndef\nghi", Charazard.html_to_plain("<p>Foo</p><p>Bar</p><p>abc<p>def<br />ghi")
    end

    test "invalid Unicode code points in numeric entities from CP1252" do
      assert_equal "that\xe2\x80\x99s \xe2\x80\x93 a test", Charazard.html_to_plain("that&#146;s &#150; a test")
    end

    test "Test common ISO-8859-1 literals" do
      assert_equal Charazard.html_to_plain("Foo&reg; Bar&trade; &copy;2010"), Charazard.html_to_plain("Foo\256 Bar\231 \2512010")
    end

    test "ISO-8859-1 capital A grave accent literal" do
      assert_equal "\xc3\x82", Charazard.html_to_plain(Charazard.html_to_plain("\xc2"))
    end

    test "Line tabulation character U+000B in HTML should be stripped" do
      assert_equal 'foobar', Charazard.html_to_plain("foo\x0bbar")
    end

    test "Newline U+000A in HTML should be preserved" do
      assert_equal "foo\nbar", Charazard.html_to_plain("foo\nbar")
    end

    test "Tab U+0009 in HTML should be normalised to space" do
      assert_equal "foo bar", Charazard.html_to_plain("foo\tbar")
    end

    test "Combination of different conversion cases in HTML to plain" do
      assert_equal "A\nB\xc3\x82CD", Charazard.html_to_plain(Charazard.html_to_plain("A\nB\xc2C\x0bD"))
    end

    test "stylesheet and script blocks should be stripped" do
      html = <<-HTML
        foo
        <script>alert('hi');</script><strong>bar</strong>
        <style type="text/css">
        body
        {
          font-face: Helvetica;
        }
        </style>
        baz
      HTML
      plain = "foo bar baz"
      assert_equal plain, Charazard.html_to_plain(html)
    end

    test "unordered lists should format as lines" do
      html = "foo<ul><li>one</li><li>two</li><li>three</li></ul>bar"
      plain = "foo\n* one\n* two\n* three\nbar"
      assert_equal plain, Charazard.html_to_plain(html)
    end

    test "ordered lists should format as lines" do
      html = "foo<ol><li>one</li><li>two</li><li>three</li></ol>bar"
      plain = "foo\n1. one\n2. two\n3. three\nbar"
      assert_equal plain, Charazard.html_to_plain(html)
    end

    test "ordered list with start offset" do
      html = "<ol start=3><li>three</li><li>four</li></ol>"
      plain = "3. three\n4. four"
      assert_equal plain, Charazard.html_to_plain(html)
    end

    test "should be converted to UTF-8" do
      input = "Foo\nBar\x99".force_encoding('ASCII-8BIT').split("\n").to_a
      expected = ["Foo", "Bar\xE2\x84\xA2"]
      actual = input.map { |str| Charazard.html_to_plain(str) }
      assert_equal expected, actual
      expected.zip(actual).each do |expected_line, actual_line|
        assert_equal expected_line.encoding, actual_line.encoding
      end
    end

    test "URL containing hyphen-less-than-hyphen passes through" do
      str = "http://example.com/age-<-5-years"
      assert_equal str, Charazard.html_to_plain(str)
    end
  end
end
