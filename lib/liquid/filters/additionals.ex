defmodule Liquid.Filters.Additionals do
  @moduledoc """
  Applies a chain of 'Additionals' filters passed from Liquid.Variable
  """

  @doc """
  Allows you to specify a fallback in case a value doesn’t exist.
  `default` will show its value if the left side is nil, false, or empty
  """
  @spec default(any(), any()) :: any()
  def default(input, default_val \\ "")

  def default(input, default_val) when input in [nil, false, '', "", [], {}, %{}],
      do: default_val

  def default(input, _), do: input

  @doc """
  Converts a timestamp into another date format.

  ## Examples

    iex>  Liquid.Filters.Additionals.date("Mon Nov 19 9:45:0 1990")
    "1990-11-19 09:45:00"
  """
  @spec date(String.t() | Date.t(), Date.t() | String.t()) :: String.t() | Date.t()
  def date(input, format \\ "%F %T")

  def date(nil, _), do: nil

  def date(input, format) when is_nil(format) or format == "" do
    date(input)
  end

  def date("now", format), do: date(Timex.now(), format)

  def date("today", format), do: date(Timex.now(), format)

  def date(input, format) when is_binary(input) do
    with {:ok, input_date} <- NaiveDateTime.from_iso8601(input) do
      input_date |> date(format)
    else
      {:error, :invalid_format} ->
        with {:ok, input_date} <- Timex.parse(input, "%a %b %d %T %Y", :strftime),
             do: input_date |> date(format)
    end
  end

  def date(input, format) do
    with {:ok, date_str} <- Timex.format(input, format, :strftime), do: date_str
  end


end
