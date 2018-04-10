defmodule Liquid.Expression do
  @moduledoc """
  This module transform strings to expressions
  """
  alias Liquid.{RangeLookup, Variable}


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

  @doc """
  Takes a markup `(string)`, if the string is in the expression list transforms it in a valid expression,
  if not it creates a variable struct `Liquid.Variable.create(markup)`
  
  ## Example:
      iex> Liquid.Expression.parse("true")
      true

      iex> Liquid.Expression.parse("hello")
      %Liquid.Variable{filters: [], literal: nil, name: "hello", parts: ["hello"]}
  """
  @spec parse(String.t()) :: String.t() | %Variable{}
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
