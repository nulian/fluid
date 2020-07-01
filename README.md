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

You can start the application as a child to your app:

```elixir
children = [
  worker(Liquid.Process, [
    :liquid,
    Application.get_env(:your_app, :liquid)
  ])
]

opts = [strategy: :one_for_one, name: Hokusai.Supervisor]
Supervisor.start_link(children, opts)
```

where config is:

```elixir
config :your_app, :liquid,
  cache_adapter: Cachex,
  filter_modules: [
    ...
  ],
  extra_tags: %{
    tag_1: {TagModule, Liquid.Tag},
    block_1: {BlockModule, Liquid.Block},
  },
  file_system: {Filesystem, "/"}
```

Or start it manually:

``` elixir
{:ok, pid} = Liquid.Process.start_link(:liquid, options)
```

where option is a keyword list, same as in config.

Every option can be overridden by a keyword list passed as last argument to `Liquid.parse_template` / `Liquid.render_template`.

Compile a template from a string:

`template = Liquid.parse_template(:liquid, "{% assign hello='hello' %}{{ hello }}{{world}}")`

Render the template with a keyword list representing the local variables:

`{ :ok, rendered, _ } = Liquid.render_template(:liquid, template, %{"world" => "world"})`

For registers you might want to use in custom tags you can assign them like this:

`{ :ok, rendered, _ } = Liquid.render_template(:liquid, template, %{"world" => "world"}, registers: %{test: "hallo")`

The tests should give a pretty good idea of the features implemented so far.

All of the public API can be viewed inside the `Liquid` module.

## Custom tags and filters

You can add your own filters and tags/blocks inside your project:

``` elixir
defmodule MyFilters do
  def meaning_of_life(_), do: 42
  def one(_), do: 1
end

defmodule ExampleTag do
  def parse(%Liquid.Tag{}=tag, %Liquid.Template{}=context, _options) do
    {tag, context}
  end

  def render(output, tag, context, _options) do
    number = tag.markup |> Integer.parse |> elem(0)
    {["#{number - 1}"] ++ output, context}
  end
end

defmodule ExampleBlock do
  def parse(b, p), do: { b, p }
end
```

and then include them in your configuration, as shown above.

Another option is to set up the tag using:
`Liquid.register_tags(:liquid, "minus_one", MinusOneTag, Liquid.Tag)`,
`Liquid.register_tags(:liquid, "my_block", ExampleBlock, Liquid.Block)` same for blocks;
and for filters you should use
`Liquid.add_filters(:liquid, MyFilters)`

#### Global Filters
It's also possible to apply a global filter to all rendered variables setting up in the config:
``` elixir
[global_filter: &MyFilter.counting_sheeps/1]
```
or adding a `"global_filter"` value to options for the `Liquid.render_template` function:
`Liquid.render_template(:liquid, :tpl, %{some: context}, global_filter: &MyFilter.counting_sheeps/1)` (you need to define the filter function first)


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
  def match(current, ["info"|_]=parts, _full_liquid_context) do
    "His name is: "<> current.name
  end
end
```
And later you can use it in your code:
``` elixir
iex> parsed_template = Liquid.parse_template(:liquid, "{{ info }}")
iex> Liquid.Template.render_template(:liquid, parsed_template, %User{}) |> elem(1)
"His name is: John"
```

## Missing Features

Feel free to add a bug report or pull request if you feel that anything is missing.
