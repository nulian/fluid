# Liquid [![Hex.pm](https://img.shields.io/hexpm/v/liquid.svg)](https://hex.pm/packages/liquid) [![Hex.pm](https://img.shields.io/hexpm/dt/liquid.svg)](https://hex.pm/packages/liquid) [![Build Status](https://travis-ci.org/bettyblocks/liquid-elixir.svg?branch=master)](https://travis-ci.org/bettyblocks/liquid-elixir)

It's a templating library for Elixir.
Continuation of the fluid liquid conversion.

## Usage

Add the dependency to your mix file:

``` elixir
# mix.exs
defp deps do
  […,
   {:liquid, "~> 0.8.0"}]
end
```

You can either start the application directly:

`Liquid.start`

Or start it with your application:

``` elixir
# mix.exs
def application do
  [mod: {MyApp, []},
   applications: […, :liquid]]
end
```

Compile a template from a string:

`template = Liquid.Template.parse("{% assign hello='hello' %}{{ hello }}{{world}}")`

Render the template with a keyword list representing the local variables:

`{ :ok, rendered, _ } = Liquid.Template.render(template, %{"world" => "world"})`

For registers you might want to use in custom tags you can assign them like this:

`{ :ok, rendered, _ } = Liquid.Template.render(template, %{"world" => "world"}, registers: %{test: "hallo")`

The tests should give a pretty good idea of the features implemented so far.

## Custom tags and filters

You can add your own filters and tags/blocks inside your project:

``` elixir
defmodule MyFilters do
  def meaning_of_life(_, _context), do: 42
  def one(_, _context), do: 1
end

defmodule ExampleTag do
  def parse(%Liquid.Tag{}=tag, %Liquid.Template{}=context) do
    {tag, context}
  end

  def render(output, tag, context) do
    number = tag.markup |> Integer.parse |> elem(0)
    {["#{number - 1}"] ++ output, context}
  end
end

defmodule ExampleBlock do
  def parse(b, p), do: { b, p }
end
```

and than include them in your `config.exs` file

``` elixir
# config.exs
config :liquid,
  extra_filter_modules: [MyFilters],
  extra_tags: %{minus_one: {ExampleTag, Liquid.Tag},
                my_block: {ExampleBlock, Liquid.Block}}
```

Another option is to set up the tag using:
`Liquid.Registers.register("minus_one", MinusOneTag, Tag)` for tag
`Liquid.Registers.register("my_block", ExampleBlock, Liquid.Block)` same for blocks;
and for filters you should use
`Liquid.Filters.add_filters(MyFilters)`

#### Global Filters 
It's also possible to apply global filter to all rendered variables setting up the config:
``` elixir
# config.exs
config :liquid,
  global_filter: &MyFilter.counting_sheeps/2
```
or adding a `"global_filter"` value to context for `Liquid.Template.render` function:
`Liquid.Template.render(tpl, %{global_filter: &MyFilter.counting_sheeps/2})` (you need to define filter function first)

## File systems
You can also set up the desired default file system for your project using the `config.exs` file 
``` elixir
# config.exs
config :liquid,
  file_system: {Liquid.LocalFileSystem, "/your/path"}
```
 

## Context assignment

`Liquid.Matcher` protocol is designed to deal with your custom data types you want to assign
For example having the following struct:
``` elixir
defmodule User do
  defstruct name: "John", age: 27, about: []
end
```
You can describe how to get the data from it:
``` elixir
defimpl Liquid.Matcher, for: User do
  def match(current, ["info"|_]=parts) do
    "His name is: "<> current.name
  end
end
```
And later you can use it in your code:
``` elixir
iex> "{{ info }}" |> Liquid.Template.parse |> Liquid.Template.render(%User{}) |> elem(1)
"His name is: John"
```

## Missing Features

Feel free to add a bug report or pull request if you feel that anything is missing.

### todo

* Fix empty check on arrays
