defmodule Liquid.Process do
  use GenServer

  # this module serves as entrypoint
  # injecting config into ETS table

  def start_link(name, options) do
    :ets.new(name, [:named_table, :set, :public])
    :ets.insert(name, {"options", augment_options(options)})

    GenServer.start_link(__MODULE__, augment_options(options), name: name)
  end

  def start_link(options) do
    {name, options} = Keyword.pop(options, :name)
    :ets.new(name, [:named_table, :set, :public])
    :ets.insert(name, {"options", augment_options(options)})

    GenServer.start_link(__MODULE__, augment_options(options), name: name)
  end


  @impl true
  def init(options), do: {:ok, options}

  @impl true
  def handle_call(_, _, options), do: {:ok, nil, options}

  @impl true
  def handle_cast(tuple, options)

  def handle_cast(_, options), do: {:no_reply, options}

  defp overridden_filter_names(module), do: Map.keys(filter_name_override_map(module))

  defp filter_name_override_map(module) do
    if function_exists?(module, :filter_name_override_map) do
      module.filter_name_override_map
    else
      %{}
    end
  end

  defp function_exists?(module, func), do: Keyword.has_key?(module.__info__(:functions), func)

  defp augment_options(options) do
    custom_filters = Keyword.get(options, :custom_filters, %{})
    filter_modules = Keyword.get(options, :filter_modules, [])

    custom_filters = Enum.reduce(filter_modules, custom_filters, fn module, acc ->
        module.__info__(:functions)
        |> Keyword.keys()
        |> Kernel.++(overridden_filter_names(module))
        |> Enum.into(%{}, fn filter_name -> {filter_name, module} end)
        |> Map.merge(acc)
      end)

    Keyword.put(options, :custom_filters, custom_filters)
  end
end
