defmodule Liquid.Process do
  use GenServer

  def start_link(name, options) do
    GenServer.start_link(__MODULE__, augment_options(options), name: name)
  end

  def start_link(options) do
    {name, options} = Keyword.pop(options, :name)

    GenServer.start_link(__MODULE__, augment_options(options), name: name)
  end


  @impl true
  def init(options), do: {:ok, options}

  @impl true
  def handle_call(tuple, from, options)

  def handle_call(
        {:render_template, template, context, extra_options},
        _from,
        options
      ) do
    try do
      output = Liquid.Template.render(template, context, Keyword.merge(options, extra_options))
      {:reply, {:ok, output}, options}
    rescue
      x -> {:reply, {:error, x, __STACKTRACE__}, options}
    end
  end

  def handle_call(
        {:parse_template, source, presets, extra_options},
        _from,
        options
      ) do
    try do
      output = Liquid.Template.parse(source, presets, Keyword.merge(options, extra_options))
      {:reply, {:ok, output}, options}
    rescue
      x -> {:reply, {:error, x, __STACKTRACE__}, options}
    end
  end

  def handle_call({:registers}, options), do: {:reply, Keyword.get(options, :extra_tags), options}

  def handle_call({:registers_lookup, name, extra_options}, _from, options),
    do: {:reply, Liquid.Registers.lookup(name, Keyword.merge(options, extra_options)), options}

  def handle_call({:read_template_file, path, extra_options}, _from, options),
    do:
      {:reply, Liquid.FileSystem.read_template_file(path, Keyword.merge(options, extra_options)),
       options}

  def handle_call({:full_path, path, extra_options}, _from, options),
    do:
      {:reply, Liquid.FileSystem.full_path(path, Keyword.merge(options, extra_options)), options}

  @impl true
  def handle_cast(tuple, options)

  def handle_cast({:register_file_system, module, path}, options) do
    new_options = Keyword.put(options, :file_system, {module, path})
    {:noreply, new_options}
  end

  def handle_cast({:clear_registers}, options) do
    new_options = Keyword.put(options, :extra_tags, %{})
    {:noreply, new_options}
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
