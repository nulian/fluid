defmodule Liquid.Expression do
  alias Liquid.Variable
  alias Liquid.RangeLookup

  @literal_list [nil, "nil", "null", "", "true", "false", "blank", "empty"]
  @literals %{
    nil => nil,
    "nil" => nil,
    "null" => nil,
    "" => nil,
    "true" => true,
    "false" => false,
    "blank" => :blank?,
    "empty" => :empty?
  }

  def parse(markup) when markup in @literal_list, do: @literals[markup]

  def parse(markup) do
    cond do
      # Single quoted strings
      Regex.match?(~r/\A'(.*)'\z/m, markup) ->
        [result] = Regex.run(~r/\A'(.*)'\z/m, markup, capture: :all_but_first)
        result

      # Double quoted strings
      Regex.match?(~r/\A"(.*)"\z/m, markup) ->
        [result] = Regex.run(~r/\A"(.*)"\z/m, markup, capture: :all_but_first)
        result

      # Integer and floats
      Regex.match?(~r/\A(-?\d+)\z/, markup) ->
        [result] = Regex.run(~r/\A(-?\d+)\z/, markup, capture: :all_but_first)
        String.to_integer(result)

      # Ranges
      Regex.match?(~r/\A\((\S+)\.\.(\S+)\)\z/, markup) ->
        [left_range, right_range] =
          Regex.run(~r/\A\((\S+)\.\.(\S+)\)\z/, markup, capture: :all_but_first)

        RangeLookup.parse(left_range, right_range)

      # Floats
      Regex.match?(~r/\A(-?\d[\d\.]+)\z/, markup) ->
        [result] = Regex.run(~r/\A(-?\d[\d\.]+)\z/, markup, capture: :all_but_first)
        result

      true ->
        Variable.create(markup)
    end
  end
end
