# Charazard

Cleans up bad character encodings with liberal application of fire.

## Usage

### Converting Windows-1252 (ISO 8859-1) to UTF-8

CSV files saved by Excel on Windows are by default encoded in Windows-1252 (which is close to but not quite ISO 8859-1 or ISO Latin 1).
`Charazard.fix_invalid_unicode_literals` can be used to convert these characters into valid UTF-8 without breaking existing UTF-8 strings.

```ruby
Charazard.fix_invalid_unicode_literals("\x93Smart quotes\x94 \xC3\x9Cber Unicode")
  # => "“Smart quotes” Über Unicode"
```

`Charazard.fix_invalid_unicode_literals` can be used in combination with
[`filter_io`](https://github.com/jasoncodes/filter_io) to filter CSV streams.
Here’s an example that handles UTF-8/ISO-8859-1 with mixed line endings:

``` ruby
require 'filter_io'
require 'charazard'
require 'csv'

File.open(filename, external_encoding: 'UTF-8') do |io|
  io = FilterIO.new(io) do |data, state|
    # fix invalid UTF-8 literals
    data = Charazard.fix_invalid_unicode_literals(data)

    # grab another chunk if the last character is a delimiter
    raise FilterIO::NeedMoreData if data =~ /[\r\n]\z/ && !state.eof?
    # normalise line endings to LF
    data = data.gsub /\r\n|\r|\n/, "\n"

    data
  end

  CSV.parse(io, row_sep: "\n") do |row|
    p row
  end
end
```

### Converting HTML to plain text

Feeds (RSS, product lists, etc.) often contain HTML which you may want to sanitize into plain text.
Charazard recognises basic formatting such as paragraphs and lists.

```html
<p>First sentence.</p><p>Second sentenence.</p>
<ul><li>foo</li><li>bar</li></ul>
```

```ruby
text = Charazard.html_to_plain(html)
```

```markdown
First sentence.
Second sentenence.
* foo
* bar
```
