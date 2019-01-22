defmodule Liquid.Combinators.Tags.CommentTest do
  use ExUnit.Case

  import Liquid.Helpers

  test "comment tag parser" do
    test_parse(
      "{% comment %} Allows you to leave un-rendered code inside a Liquid template. Any text within the opening and closing comment blocks will not be output, and any Liquid code within will not be executed. {% endcomment %}",
      comment: [
        " Allows you to leave un-rendered code inside a Liquid template. Any text within the opening and closing comment blocks will not be output, and any Liquid code within will not be executed. "
      ]
    )
  end

  test "comment with tags and variables in body" do
    test_parse(
      "{% comment %} {% if true %} {% endcomment %}",
      comment: [" {% if true %} "]
    )
  end

  test "comment with any tags in body" do
    test_parse(
      "{% comment %} {% if true %} sadsadasd  {% afi true %}{% endcomment %}",
      comment: [" {% if true %} sadsadasd  {% afi true %}"]
    )
  end

  test "comment with any tags and comments or raw in body" do
    test_parse(
      "{% comment %} {% if true %} {% comment %} {% if true %} {% endcomment %} {% endcomment %}",
      comment: [" {% if true %}  {% if true %}  "]
    )
  end

  test "comment with any tags and nested comment" do
    test_parse(
      "{% comment %} {% comment %} {% if true %} {% comment %} {% if true %} {% endcomment %} {% endcomment %} {% endcomment %}",
      comment: ["  {% if true %}  {% if true %}   "]
    )

    test_parse(
      "{% comment %} {% comment %} {% comment %}   {% comment %}  {% comment %} {% comment %} {% endcomment %} {% endcomment %}  {% endcomment %}{% endcomment %} {% endcomment %} {% endcomment %}",
      comment: ["              "]
    )

    test_parse(
      "{% comment %} a {% comment %} b {% endcomment %} {% comment %} c{% endcomment %} {% comment %} d {% endcomment %}{% endcomment %}",
      comment: [" a  b   c  d "]
    )

    test_parse(
      "{% comment %} a {% comment %} b {% endcomment %} {% comment %} c{% endcomment %} {% comment %} d {% endcomment %}{% endcomment %}",
      comment: [" a  b   c  d "]
    )

    test_parse(
      "{% comment %} hi {% endcomment %}{% comment %} there {% endcomment %}",
      comment: [" hi "],
      comment: [" there "]
    )
  end

  test "comment with any tag that are similar to comment and endcomment" do
    test_parse(
      "{% comment %} {% if true %} {% andcomment %} {% aendcomment %} {% acomment %} {% endcomment %}",
      comment: [" {% if true %} {% andcomment %} {% aendcomment %} {% acomment %} "]
    )

    test_parse(
      "{% comment %} {% commenta %} {% endcomment %}",
      comment: [" {% commenta %} "]
    )
  end

  test "comment with several raw" do
    test_parse(
      "{% comment %} {% raw %} {% comment %} {% endraw %} {% raw %} {% endcomment %}{% endraw %} {% raw %} hi there .. {% endraw %}{% endcomment %}",
      comment: ["  {% comment %}   {% endcomment %}  hi there .. "]
    )

    test_parse(
      "{% comment %} {% raw %} {% comment %} {% endraw %} {% comment %} hi {% endcomment %} {% raw %} i am raw text .. {% endraw %} {% comment %} i am  a comment {% endcomment %}{% endcomment %}",
      comment: ["  {% comment %}   hi   i am raw text ..   i am  a comment "]
    )

    test_parse(
      "{% comment %}{% raw %}any {% endraw %}{% if true %}{% endcomment %}",
      comment: ["any {% if true %}"]
    )

    test_parse(
      "{% comment %}{% raw %}any {% endraw %}{% if true %}{% endif %}{% for item in products %}{% endfor %}{% endcomment %}",
      comment: ["any {% if true %}{% endif %}{% for item in products %}{% endfor %}"]
    )

    test_parse(
      "{% comment %}{% raw %}any {% endraw %}{% if true %}{% endif %}{% for item in products %}{%%}{% endcomment %}",
      comment: ["any {% if true %}{% endif %}{% for item in products %}{%%}"]
    )
  end

  test "comment start and end tags" do
    test_parse(
      "{%            comment      \n\n\n %}%}{%   \n\n\n     endcomment \n\n\n %}",
      comment: ["%}"]
    )

    test_parse(
      "{% comment %}{%%}{%%}{%%}{%%}{%%}{% endcomment %}",
      comment: ["{%%}{%%}{%%}{%%}{%%}"]
    )
  end

  test "comment must fails with this one" do
    test_combinator_error(
      "{% comment %} {% if true %} {% comment %} {% aendcomment %} {% acomment %} {% endcomment %}"
    )

    test_combinator_error("{% comment %}{%}{% endcomment %}")
    test_combinator_error("{% comment %} {% comment %} {% endcomment %}")
    test_combinator_error("{%comment%}{%comment%}{%endcomment%}")
    test_combinator_error("{% comment %} {% endcomment %} {% endcomment %}")
  end
end
