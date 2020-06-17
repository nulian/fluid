defmodule Liquid.Template do
  @moduledoc """
  Main Liquid module, all further render and parse processing passes through it
  """

  defstruct root: nil, presets: %{}, blocks: [], errors: [], filename: :root
  alias Liquid.{Template, Render, Context}

  @doc """
  Function that renders passed template and context to string
  """
  @file "render.ex"
  @spec render(Liquid.Template, map, Keyword.t()) :: String.t()
  def render(t, c \\ %{}, options)

  def render(%Template{} = t, %Context{} = c, options) do
    registers = Keyword.get(options, :registers, %{})
    new_registers =
      c
      |> Map.get(:registers, %{})
      |> Map.merge(registers)

    c = %{c | registers: new_registers}
    c = %{c | blocks: t.blocks}
    c = %{c | presets: t.presets}
    c = %{c | template: t}
    Render.render(t, c, options)
  end

  def render(%Template{} = t, assigns, options) when is_map(assigns) do
    context = %Context{assigns: assigns}

    context =
      case {Map.has_key?(assigns, "global_filter"), Map.has_key?(assigns, :global_filter)} do
        {true, _} ->
          %{context | global_filter: Map.fetch!(assigns, "global_filter")}

        {_, true} ->
          %{context | global_filter: Map.fetch!(assigns, :global_filter)}

        _ ->
          %{
            context
            | global_filter: Keyword.get(options, :global_filter, nil),
              extra_tags: Keyword.get(options, :extra_tags, %{})
          }
      end

    render(t, context, options)
  end

  def render(_, _, _) do
    raise Liquid.SyntaxError, message: "You can use only maps/structs to hold context data"
  end

  @doc """
  Function to parse markup with given presets (if any)
  """
  @spec parse(String.t(), map) :: Liquid.Template
  def parse(value, presets \\ %{}, filename \\ :root, options)

  def parse(<<markup::binary>>, presets, filename, options) do
    Liquid.Parse.parse(markup, %Template{presets: presets, filename: filename}, options)
  end

  @spec parse(nil, map) :: Liquid.Template
  def parse(nil, presets, filename, options) do
    Liquid.Parse.parse("", %Template{presets: presets, filename: filename}, options)
  end
end
