defmodule Liquid do
  def render_template(name, template, context \\ %{}, extra_options \\ []),
    do:
      Liquid.Template.render(template, context, name |> options() |> Keyword.merge(extra_options))

  def parse_template(name, source, presets \\ %{}, extra_options \\ []),
    do: Liquid.Template.parse(source, presets, name |> options() |> Keyword.merge(extra_options))

  def register_file_system(name, module, path \\ "/") do
    new_options = name |> options() |> Keyword.put(:file_system, {module, path})

    :ets.insert(name, {"options", new_options})

    :ok
  end

  def clear_registers(name) do
    new_options = name |> options() |> Keyword.put(:extra_tags, %{})

    :ets.insert(name, {"options", new_options})

    :ok
  end

  def clear_extra_tags(name), do: clear_registers(name)

  def register_tags(name, tag_name, module, type) do
    custom_tags = name |> options() |> Keyword.get(:extra_tags, %{})

    custom_tags =
      %{(tag_name |> String.to_atom()) => {module, type}}
      |> Map.merge(custom_tags)

    new_options = name |> options() |> Keyword.put(:extra_tags, custom_tags)

    :ets.insert(name, {"options", new_options})

    :ok
  end

  def registers(name), do: name |> options() |> Keyword.get(:extra_tags)

  def registers_lookup(name, tag_name, extra_options \\ []),
    do: Liquid.Registers.lookup(tag_name, name |> options() |> Keyword.merge(extra_options))

  def add_filters(name, module) do
    custom_filters = name |> options() |> Keyword.get(:custom_filters, %{})

    module_functions =
      module.__info__(:functions)
      |> Keyword.keys()
      |> Kernel.++(overridden_filter_names(module))
      |> Enum.into(%{}, fn filter_name -> {filter_name, module} end)

    custom_filters = module_functions |> Map.merge(custom_filters)
    new_options = name |> options() |> Keyword.put(:custom_filters, custom_filters)

    :ets.insert(name, {"options", new_options})

    :ok
  end

  def read_template_file(name, path, extra_options \\ []),
    do:
      Liquid.FileSystem.read_template_file(
        path,
        name |> options() |> Keyword.merge(extra_options)
      )

  def full_path(name, path, extra_options \\ []),
    do: Liquid.FileSystem.full_path(path, name |> options() |> Keyword.merge(extra_options))

  defp options(name) do
    [{_, options}] = :ets.lookup(name, "options")
    options
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
