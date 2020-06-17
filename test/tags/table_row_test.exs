Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule Liquid.TableRowTest do
  use ExUnit.Case

  setup do
    start_supervised!({Liquid.Process, [name: :liquid]})
    :ok
  end

  test :test_table_row do
    assert_template_result(
      "a<tr class=\"row1\">\n<td class=\"col1\"> 1 </td><td class=\"col2\"> 2 </td><td class=\"col3\"> 3 </td></tr>\n<tr class=\"row2\"><td class=\"col1\"> 4 </td><td class=\"col2\"> 5 </td><td class=\"col3\"> 6 </td></tr>\n",
      "a{% tablerow n in numbers cols:3%} {{n}} {% endtablerow %}",
      %{"numbers" => [1, 2, 3, 4, 5, 6]}
    )

    assert_template_result(
      "a<tr class=\"row1\">\n</tr>\n",
      "a{% tablerow n in numbers cols:3%} {{n}} {% endtablerow %}",
      %{"numbers" => []}
    )
  end

  test "tablerow class ids not related to numbers" do
    assert_template_result(
      "<tr class=\"row1\">\n<td class=\"col1\"> 2 </td><td class=\"col2\"> 3 </td></tr>\n",
      "{% tablerow n in (2..3) cols:3%} {{n}} {% endtablerow %}"
    )
  end

  test :test_table_row_with_different_cols do
    assert_template_result(
      "<tr class=\"row1\">\n<td class=\"col1\"> 1 </td><td class=\"col2\"> 2 </td><td class=\"col3\"> 3 </td><td class=\"col4\"> 4 </td><td class=\"col5\"> 5 </td></tr>\n<tr class=\"row2\"><td class=\"col1\"> 6 </td></tr>\n",
      "{% tablerow n in numbers cols:5%} {{n}} {% endtablerow %}",
      %{"numbers" => [1, 2, 3, 4, 5, 6]}
    )
  end

  test :test_table_col_counter do
    assert_template_result(
      "<tr class=\"row1\">\n<td class=\"col1\">1</td><td class=\"col2\">2</td></tr>\n<tr class=\"row2\"><td class=\"col1\">1</td><td class=\"col2\">2</td></tr>\n<tr class=\"row3\"><td class=\"col1\">1</td><td class=\"col2\">2</td></tr>\n",
      "{% tablerow n in numbers cols:2%}{{tablerowloop.col}}{% endtablerow %}",
      %{"numbers" => [1, 2, 3, 4, 5, 6]}
    )
  end

  test :test_quoted_fragment do
    assert_template_result(
      "<tr class=\"row1\">\n<td class=\"col1\"> 1 </td><td class=\"col2\"> 2 </td><td class=\"col3\"> 3 </td></tr>\n<tr class=\"row2\"><td class=\"col1\"> 4 </td><td class=\"col2\"> 5 </td><td class=\"col3\"> 6 </td></tr>\n",
      "{% tablerow n in collections.frontpage cols:3%} {{n}} {% endtablerow %}",
      %{"collections" => %{"frontpage" => [1, 2, 3, 4, 5, 6]}}
    )

    assert_template_result(
      "<tr class=\"row1\">\n<td class=\"col1\"> 1 </td><td class=\"col2\"> 2 </td><td class=\"col3\"> 3 </td></tr>\n<tr class=\"row2\"><td class=\"col1\"> 4 </td><td class=\"col2\"> 5 </td><td class=\"col3\"> 6 </td></tr>\n",
      "{% tablerow n in collections[\"frontpage\"] cols:3%} {{n}} {% endtablerow %}",
      %{"collections" => %{"frontpage" => [1, 2, 3, 4, 5, 6]}}
    )
  end

  #  test :test_enumerable_drop do
  #    assert_template_result("<tr class=\"row1\">\n<td class=\"col1\"> 1 </td><td class=\"col2\"> 2 </td><td class=\"col3\"> 3 </td></tr>\n<tr class=\"row2\"><td class=\"col1\"> 4 </td><td class=\"col2\"> 5 </td><td class=\"col3\"> 6 </td></tr>\n",
  #      "{% tablerow n in numbers cols:3%} {{n}} {% endtablerow %}",
  #      %{"numbers"=> %ArrayDrop{"list"=>[1, 2, 3, 4, 5, 6]}})
  #  end

  test :test_offset_and_limit do
    assert_template_result(
      "<tr class=\"row1\">\n<td class=\"col1\"> 1 </td><td class=\"col2\"> 2 </td><td class=\"col3\"> 3 </td></tr>\n<tr class=\"row2\"><td class=\"col1\"> 4 </td><td class=\"col2\"> 5 </td><td class=\"col3\"> 6 </td></tr>\n",
      "{% tablerow n in numbers cols:3 offset:1 limit:6%} {{n}} {% endtablerow %}",
      %{"numbers" => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]}
    )
  end

  test :test_blank_string_not_iterable do
    assert_template_result(
      "<tr class=\"row1\">\n</tr>\n",
      "{% tablerow char in characters cols:3 %}I WILL NOT BE OUTPUT{% endtablerow %}",
      %{"characters" => ""}
    )
  end

  test "continue in tablerow" do
    assert_template_result(
      "<tr class=\"row1\">\n<td class=\"col1\">1</td><td class=\"col2\">2</td><td class=\"col3\">3</td><td class=\"col4\"></td><td class=\"col5\"></td><td class=\"col6\"></td><td class=\"col7\"></td></tr>\n",
      "{% tablerow i in (1..7) %}{% if i > 3 %}{% continue %}{% endif %}{{ i }}{% endtablerow %}"
    )
  end

  defp assert_template_result(expected, markup, assigns \\ %{}) do
    assert_result(expected, markup, assigns)
  end

  defp assert_result(expected, markup, assigns) do
    t = Liquid.parse_template(:liquid, markup)
    {:ok, rendered, _} = Liquid.render_template(:liquid, t, assigns)
    assert rendered == expected
  end
end
