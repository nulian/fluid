defmodule Liquid do
  use GenServer # main supervisor

  @timeout 5_000

  def start_link(name, options) do
    GenServer.start_link(__MODULE__, options, name: name)
  end

  def start_link(options) do
    {name, options} = Keyword.pop(options, :name)

    GenServer.start_link(__MODULE__, options, name: name)
  end

  @impl true
  def init(options), do: {:ok, options}

  def handle_call(
    {:render_template, template, context},
    _from,
    options
  ) do
    {:reply, Liquid.Template.render(template, context, options), options}
  end

  def handle_call(
    {:parse_template, source, presets},
    _from,
    options
  ) do
    reply = Liquid.Template.parse(source, presets, options)
    {:reply, reply, options}
  end

  def handle_cast({:register_file_system, module, path}, options) do
    new_options = Keyword.put(options, :file_system, {module, path})
    {:noreply, new_options}
  end

  def handle_cast({:clear_registers}, options) do
    new_options = Keyword.put(options, :extra_tags, %{})
    {:noreply, new_options}
  end

  def handle_call({:registers}, options), do:
    {:reply, Keyword.get(options, :extra_tags), options}

    def handle_call({:registers_lookup, name}, _from, options) do
      {:reply, Liquid.Registers.lookup(name, options), options}
    end

  def handle_cast({:register_tags, tag_name, module, type}, options) do
    custom_tags = Keyword.get(options, :extra_tags, %{})

    custom_tags =
      %{(tag_name |> String.to_atom()) => {module, type}}
      |> Map.merge(custom_tags)

    new_options = Keyword.put(options, :extra_tags, custom_tags)
    {:noreply, new_options}
  end


  def handle_cast({:add_filters, module}, options) do
    custom_filters = Keyword.get(options, :custom_filters, %{})

    module_functions =
      module.__info__(:functions)
      |> Keyword.keys()
      |> Kernel.++(overridden_filter_names(module))
      |> Enum.into(%{}, fn filter_name -> {filter_name, module} end)

    custom_filters = module_functions |> Map.merge(custom_filters)
    new_options = Keyword.put(options, :custom_filters, custom_filters)

    {:noreply, new_options}
  end

  def render_template(name, template, context), do:
    GenServer.call(name, {:render_template, template, context}, @timeout)

  def parse_template(name, source, presets \\ []), do:
    GenServer.call(name, {:parse_template, source, presets}, @timeout)

  def register_file_system(name, module, path), do:
    GenServer.cast(name, {:register_file_system, module, path})

  def clear_registers(name), do:
    GenServer.cast(name, {:clear_registers})

  def clear_extra_tags(name), do: clear_registers(name)

  def register_tags(name, tag_name, module, type), do:
    GenServer.cast(name, {:register_tags, tag_name, module, type})

  def registers(name, tag_name, module, type), do:
    GenServer.call(name, {:registers}, @timeout)

  def registers_lookup(name, tag_name), do: GenServer.call(name, {:registers_lookup, tag_name}, @timeout)

  def add_filters(name, filter_module), do:
    GenServer.cast(name, {:add_filter_modules, filter_module})

    defp overridden_filter_names(module), do: Map.keys(filter_name_override_map(module))


  defp filter_name_override_map(module) do
    if function_exists?(module, :filter_name_override_map) do
      module.filter_name_override_map
    else
      %{}
    end
  end

  defp function_exists?(module, func), do: Keyword.has_key?(module.__info__(:functions), func)

  # Liquid.Template.render(template, context)
  # Liquid.Template.parse
  # Liquid.Render.render - todo later

  # def start do
  #   add_filter_modules()
  #   Liquid.Supervisor.start_link()
  # end

  # def stop, do: {:ok, "stopped"}

  # def add_filter_modules() do
  #   Liquid.Filters.add_filter_modules()
  # end

  @compile {:inline, argument_separator: 0}
  @compile {:inline, filter_argument_separator: 0}
  @compile {:inline, filter_quoted_string: 0}
  @compile {:inline, filter_quoted_fragment: 0}
  @compile {:inline, filter_arguments: 0}
  @compile {:inline, single_quote: 0}
  @compile {:inline, double_quote: 0}
  @compile {:inline, quote_matcher: 0}
  @compile {:inline, variable_start: 0}
  @compile {:inline, variable_end: 0}
  @compile {:inline, variable_incomplete_end: 0}
  @compile {:inline, tag_start: 0}
  @compile {:inline, tag_end: 0}
  @compile {:inline, any_starting_tag: 0}
  @compile {:inline, invalid_expression: 0}
  @compile {:inline, tokenizer: 0}
  @compile {:inline, parser: 0}
  @compile {:inline, template_parser: 0}
  @compile {:inline, partial_template_parser: 0}
  @compile {:inline, quoted_string: 0}
  @compile {:inline, quoted_fragment: 0}
  @compile {:inline, tag_attributes: 0}
  @compile {:inline, variable_parser: 0}
  @compile {:inline, filter_parser: 0}

  def argument_separator, do: ","
  def filter_argument_separator, do: ":"
  def filter_quoted_string, do: "\"[^\"]*\"|'[^']*'"

  def filter_quoted_fragment,
    do: "#{filter_quoted_string()}|(?:[^\s,\|'\":]|#{filter_quoted_string()})+"

  # (?::|,)\s*((?:\w+\s*\:\s*)?"[^"]*"|'[^']*'|(?:[^ ,|'":]|"[^":]*"|'[^':]*')+):?\s*((?:\w+\s*\:\s*)?"[^"]*"|'[^']*'|(?:[^ ,|'":]|"[^":]*"|'[^':]*')+)?
  def filter_arguments,
    do:
      ~r/(?:#{filter_argument_separator()}|#{argument_separator()})\s*((?:\w+\s*\:\s*)?#{
        filter_quoted_fragment()
      }):?\s*(#{filter_quoted_fragment()})?/

  def single_quote, do: "'"
  def double_quote, do: "\""
  def quote_matcher, do: ~r/#{single_quote()}|#{double_quote()}/

  def variable_start, do: "{{"
  def variable_end, do: "}}"
  def variable_incomplete_end, do: "\}\}?"

  def tag_start, do: "{%"
  def tag_end, do: "%}"

  def any_starting_tag, do: "(){{()|(){%()"

  def invalid_expression,
    do: ~r/^{%.*}}$|^{{.*%}$|^{%.*([^}%]}|[^}%])$|^{{.*([^}%]}|[^}%])$|(^{{|^{%)/ms

  def tokenizer,
    do: ~r/()#{tag_start()}.*?#{tag_end()}()|()#{variable_start()}.*?#{variable_end()}()/

  def parser,
    do:
      ~r/#{tag_start()}\s*(?<tag>.*?)\s*#{tag_end()}|#{variable_start()}\s*(?<variable>.*?)\s*#{
        variable_end()
      }/ms

  def template_parser, do: ~r/#{partial_template_parser()}|#{any_starting_tag()}/ms

  def partial_template_parser,
    do: "()#{tag_start()}.*?#{tag_end()}()|()#{variable_start()}.*?#{variable_incomplete_end()}()"

  def quoted_string, do: "\"[^\"]*\"|'[^']*'"
  def quoted_fragment, do: "#{quoted_string()}|(?:[^\s,\|'\"]|#{quoted_string()})+"

  def tag_attributes, do: ~r/(\w+)\s*\:\s*(#{quoted_fragment()})/
  def variable_parser, do: ~r/\[[^\]]+\]|[\w\-]+/
  def filter_parser, do: ~r/(?:\||(?:\s*(?!(?:\|))(?:#{quoted_fragment()}|\S+)\s*)+)/

  defp ensure_unused(name) do
    case GenServer.whereis(name) do
      nil -> { :ok, true }
      pid -> { :error, { :already_started, pid } }
    end
  end

  defmodule List do
    def even_elements([_, h | t]) do
      [h] ++ even_elements(t)
    end

    def even_elements([]), do: []
  end

  defmodule Atomizer do
    def to_existing_atom(string) do
      try do
        String.to_existing_atom(string)
      rescue
        ArgumentError -> nil
      end
    end
  end
end
