defmodule Liquid.Context do
  defstruct assigns: %{},
            offsets: %{},
            registers: %{},
            presets: %{},
            blocks: [],
            extended: false,
            continue: false,
            break: false,
            template: nil,
            global_filter: nil,
            extra_tags: %{}

  def registers(context, key) do
    context.registers |> Map.get(key)
  end
end
