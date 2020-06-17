defmodule Liquid do
  @timeout 5_000

  def render_template(name, template, context \\ %{}, extra_options \\ []) do
    case GenServer.call(name, {:render_template, template, context, extra_options}, @timeout) do
      {:ok, v} -> v
      {:error, error, stacktrace} -> reraise error, stacktrace
    end
  end

  def parse_template(name, source, presets \\ %{}, extra_options \\ []) do
    case GenServer.call(name, {:parse_template, source, presets, extra_options}, @timeout) do
      {:ok, v} -> v
      {:error, error, stacktrace} -> reraise error, stacktrace
    end
  end

  def register_file_system(name, module, path \\ "/"),
    do: GenServer.cast(name, {:register_file_system, module, path})

  def clear_registers(name), do: GenServer.cast(name, {:clear_registers})

  def clear_extra_tags(name), do: clear_registers(name)

  def register_tags(name, tag_name, module, type),
    do: GenServer.cast(name, {:register_tags, tag_name, module, type})

  def registers(name), do: GenServer.call(name, {:registers}, @timeout)

  def registers_lookup(name, tag_name, extra_options \\ []),
    do: GenServer.call(name, {:registers_lookup, tag_name, extra_options}, @timeout)

  def add_filters(name, filter_module), do: GenServer.cast(name, {:add_filters, filter_module})

  def read_template_file(name, path, extra_options \\ []),
    do: GenServer.call(name, {:read_template_file, path, extra_options}, @timeout)

  def full_path(name, path, extra_options \\ []),
    do: GenServer.call(name, {:full_path, path, extra_options}, @timeout)

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
