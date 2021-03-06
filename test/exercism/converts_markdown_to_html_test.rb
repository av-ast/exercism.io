require './test/integration_helper'
require 'mocha/setup'

class ConvertsMarkdownToHTMLTest < Minitest::Test

  def check_sanitisation(input, expected)
    converter = ConvertsMarkdownToHTML.new(input)
    converter.convert
    assert_equal expected, converter.content.strip
  end

  def test_convert_class_method_calls_correct_methods
    ConvertsMarkdownToHTML.any_instance.expects(:convert)
    ConvertsMarkdownToHTML.any_instance.expects(:content)
    ConvertsMarkdownToHTML.convert(nil)
  end

  def test_convert_calls_correct_methods
    converter = ConvertsMarkdownToHTML.new(nil)
    converter.expects(:convert_markdown_to_html)
    converter.expects(:sanitize_html)
    converter.convert
  end

  def test_sanitisation
    input = "<script type=\"text/javascript\">bad();</script>good"
    expected = "<p>&lt;script type=\"text/javascript\"&gt;bad();&lt;/script&gt;good</p>"
    check_sanitisation(input, expected)
  end

  def test_markdown
    input = "Foo **bold** bar"
    expected = "<p>Foo <strong>bold</strong> bar</p>"
    check_sanitisation(input, expected)
  end

  def test_markdown_code_with_ampersands
    input = "```\nbig && strong\n```"
    expected = %Q{<div class=\"highlight plaintext\">
  <table>
    <tbody>
      <tr>
        <td class=\"gutter gl\">
          <pre class=\"lineno\">1</pre>
        </td>
        <td class=\"code\">
          <pre>big &amp;&amp; strong
</pre>
        </td>
      </tr>
    </tbody>
  </table>
</div>}
    check_sanitisation(input, expected)
  end

  def test_markdown_code_with_text_and_double_braces
    input = "```\nx{{current}}y\n```"
    expected = %Q{<div class=\"highlight plaintext\">
  <table>
    <tbody>
      <tr>
        <td class=\"gutter gl\">
          <pre class=\"lineno\">1</pre>
        </td>
        <td class=\"code\">
          <pre>x{{current}}y
</pre>
        </td>
      </tr>
    </tbody>
  </table>
</div>}
    check_sanitisation(input, expected)
  end

  def test_markdown_code_with_double_braces
    input = "```\n{{x: y}}\n```"
    expected = %Q{<div class=\"highlight json\">
  <table>
    <tbody>
      <tr>
        <td class=\"gutter gl\">
          <pre class=\"lineno\">1</pre>
        </td>
        <td class=\"code\">
          <pre>
            <span class=\"p\">{</span>
            <span class=\"err\">{x</span>
            <span class=\"p\">:</span>
            <span class=\"w\"> </span>
            <span class=\"err\">y</span>
            <span class=\"p\">}</span>
            <span class=\"err\">}</span>
            <span class=\"w\">
</span>
          </pre>
        </td>
      </tr>
    </tbody>
  </table>
</div>}

    check_sanitisation(input, expected)
  end

  def test_markdown_code_with_javascript_and_double_braces
    input = %Q{```
  var refill = 99
    , template = "{{current}} of beer on the wall, {{current}} of beer.\n" +
                 "{{action}}, {{remaining}} of beer on the wall.\n";}

    expected = %Q{<div class=\"highlight plaintext\">
  <table>
    <tbody>
      <tr>
        <td class=\"gutter gl\">
          <pre class=\"lineno\">1</pre>
          <pre class=\"lineno\">2</pre>
          <pre class=\"lineno\">3</pre>
          <pre class=\"lineno\">4</pre>
          <pre class=\"lineno\">5</pre>
        </td>
        <td class=\"code\">
          <pre>  var refill = 99
    , template = "{{current}} of beer on the wall, {{current}} of beer.\n" +
                 "{{action}}, {{remaining}} of beer on the wall.\n";
</pre>
        </td>
      </tr>
    </tbody>
  </table>
</div>}

    converter = ConvertsMarkdownToHTML.new(input)
    converter.convert
    assert_equal expected, converter.content.strip
  end


  def test_complex_markdown_with_code
    input = %Q{Pre text

```
class Foobar
  foos.each { |foo| foo.bar > 10 }
end
```

Post text}

    expected = %q{<p>Pre text</p>
<div class="highlight plaintext">
  <table>
    <tbody>
      <tr>
        <td class="gutter gl">
          <pre class="lineno">1</pre>
          <pre class="lineno">2</pre>
          <pre class="lineno">3</pre>
        </td>
        <td class="code">
          <pre>class Foobar
  foos.each { |foo| foo.bar &gt; 10 }
end
</pre>
        </td>
      </tr>
    </tbody>
  </table>
</div>
<p>Post text</p>}

    check_sanitisation(input, expected)
  end

  def test_stubby_lambda
    input = "->"
    expected = "<p>-&gt;</p>"
    check_sanitisation(input, expected)
  end

  def test_elixir_operator
    input = "->>"
    expected = "<p>-&gt;&gt;</p>"
    check_sanitisation(input, expected)
  end

  def test_ascii_hearts
    input = "<3 This is lovely!"
    expected = "<p>&lt;3 This is lovely!</p>"
    check_sanitisation(input, expected)
  end
end
