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

  @type t :: %__MODULE__{
          assigns: map(),
          offsets: map(),
          registers: map(),
          presets: map(),
          blocks: list(),
          extended: boolean(),
          continue: boolean(),
          break: boolean(),
          template: term(),
          global_filter: term(),
          extra_tags: map()
        }

  def registers(context, key) do
    context.registers |> Map.get(key)
  end
end
