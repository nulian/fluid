defmodule Liquid.Filters do
  import Kernel, except: [round: 1]
  alias Liquid.HTML

  defmodule Functions do
    def size(input) when is_binary(input) do
      String.length(input)
    end

    def size(input) when is_list(input) do
      length(input)
    end

    def size(input) when is_tuple(input) do
      tuple_size(input)
    end

    def size(_), do: 0

    def downcase(input) do
      input |> to_string |> String.downcase
    end

    def upcase(input) do
      input |> to_string |> String.upcase
    end

    def capitalize(input) do
      input |> to_string |> String.capitalize
    end

    def first(array) when is_list(array), do: array |> List.first

    def last(array) when is_list(array), do: array |> List.last

    def reverse(array), do: array |> to_iterable |> Enum.reverse

    def sort(array), do: array |> Enum.sort

    def sort(array, key) when is_list(array) and is_map(hd(array)) do
      array |> Enum.sort_by(&(&1[key]))
    end

    def sort(array, _) when is_list(array) do
      array |> Enum.sort
    end

    def uniq(array) when is_list(array), do: array |> Enum.uniq

    def uniq(_), do: raise "Called `uniq` with non-list parameter."

    def uniq(array, key) when is_list(array) and is_map(hd(array)) do
      array |> Enum.uniq_by(&(&1[key]))
    end

    def uniq(array, _) when is_list(array) do
      array |> Enum.uniq
    end

    def uniq(_, _), do: raise "Called `uniq` with non-list parameter."


    def join(array, separator \\ " ") do
      array |> to_iterable |> Enum.join(separator)
    end

    def map(array, key) when is_list(array) do
      with mapped <- array |> Enum.map(fn(arg) -> arg[key] end) do
        case Enum.all?(mapped, &is_binary/1) do
          true -> mapped |> Enum.reduce("",fn(el, acc) -> acc <> el end)
          _ -> mapped
        end
      end
    end

    def map(_, _), do: ""

    def plus(value, operand) when is_number(value) and is_number(operand) do
      value + operand
    end

    def plus(value, <<operand::binary>>) when is_number(value) do
      plus value, to_number(operand)
    end

    def plus(<<value::binary>>, <<operand::binary>>) do
      value |> to_number |> plus(to_number(operand))
    end

    def minus(value, operand) when is_number(value) and is_number(operand) do
      value - operand
    end

    def minus(value, <<operand::binary>>) when is_number(value) do
      minus value, to_number(operand)
    end

    def minus(<<value::binary>>, <<operand::binary>>) do
      value |> to_number |> minus(to_number(operand))
    end

    def times(value, operand) when is_integer(value) and is_integer(operand) do
      value * operand
    end

    def times(value, operand) do
      {value_int, value_len} = value |> get_int_and_counter
      {operand_int, operand_len} = operand |> get_int_and_counter
      case value_len + operand_len do
        0 -> value_int * operand_int
        precision -> (value_int * operand_int / :math.pow(10, precision)) |> Float.round(precision)
      end
    end

    def divided_by(input, operand) when is_number(input) do
      case {input, operand |> to_number} do
        {_, 0} -> raise ArithmeticError, message: "divided by 0"
        {input, number_operand} when is_integer(input) ->
          input / number_operand |> floor
        {input, number_operand} ->
          input / number_operand
      end
    end

    def divided_by(input, operand) do
      input |> to_number |> divided_by(operand)
    end


    def floor(input) when is_integer(input), do: input

    def floor(input) when is_number(input), do: input |> trunc

    def floor(input), do: input |> to_number |> floor

    def floor(input, precision) when is_number(precision) do
      input |> to_number |> Float.floor(precision)
    end

    def floor(input, precision) do
      input |> floor(to_number(precision))
    end


    def ceil(input) when is_integer(input), do: input

    def ceil(input) when is_number(input) do
      input |> Float.ceil |> trunc
    end

    def ceil(input), do: input |> to_number |> ceil

    def ceil(input, precision) when is_number(precision) do
      input |> to_number |> Float.ceil(precision)
    end

    def ceil(input, precision) do
      input |> ceil(to_number(precision))
    end

    def round(input) when is_integer(input), do: input

    def round(input) when is_number(input) do
      input |> Float.round |> trunc
    end

    def round(input), do: input |> to_number |> round

    def round(input, precision) when is_number(precision) do
      input |> to_number |> Float.round(precision)
    end

    def round(input, precision) do
      input |> round(to_number(precision))
    end


    def default(input,default_val\\"")

    def default(input, default_val) when is_nil(input), do: default_val

    def default(input, default_val) when input == "", do: default_val

    def default(input, default_val) when input == false, do: default_val

    def default(input, default_val) when input == {}, do: default_val

    def default(input, default_val) when input == [], do: default_val

    def default(input, default_val) when input == %{}, do: default_val

    def default(input, _), do: input


    # def modulo(input) when is_number(input) do
    #   # mod operation is included in the latest(31.09.16) build of elixir
    #   # elixir 1.3.0 doesn't support it
    # end


    def truncate(input, l \\ 50)

    def truncate(nil, _), do: nil

    def truncate(input, l) do
      truncate_string = "..."
      l = l - String.length(truncate_string) - 1
      case {l, String.length(input)} do
        {l, _} when l <= 0 -> truncate_string
        {l, len} when l < len -> String.slice(input,0..l) <> truncate_string
        _ -> input
      end
    end
    
    def truncatewords(input, words \\ 15)

    def truncatewords(nil, _), do: nil

    def truncatewords(input, words) do
      truncate_string = "..."
      wordlist = input |> String.split(" ")
      case words - 1 do
        l when l < 0 -> wordlist[0]
        l when l < length(wordlist) ->
          words = wordlist |> Enum.slice(0..l) |> Enum.join(" ") 
          words <> truncate_string
        _ -> input
      end
    end


    def replace(<<string::binary>>, <<from::binary>>, <<to::binary>>) do
      string |> String.replace(from, to)
    end

    def replace(<<string::binary>>, <<from::binary>>, to) do
      string |> replace(from, to_string(to))
    end

    def replace(<<string::binary>>, from, to) do
      string |> replace(to_string(from), to)
    end

    def replace(string, from, to) do
      string |> to_string |> replace(from, to)
    end

    def replace_first(<<string::binary>>, <<from::binary>>, to) do
      string |> String.replace(from, to_string(to), global: false)
    end

    def replace_first(string, from, to) do
      to = to |> to_string
      string |> to_string |> String.replace(to_string(from), to, global: false)
    end

    def remove(<<string::binary>>, <<remove::binary>>) do
      string |> String.replace(remove, "")
    end

    def remove_first(<<string::binary>>, <<remove::binary>>) do
      string |> String.replace(remove, "", global: false)
    end

    def remove_first(string, operand) do
      string |> to_string |> remove_first(to_string(operand))
    end

    def append(<<string::binary>>, <<operand::binary>>) do
      string <> operand
    end

    def append(string, operand) do
      string |> to_string |> append(to_string(operand))
    end

    def append(input, nil), do: input

    def prepend(<<string::binary>>, <<addition::binary>>) do
      addition <> string
    end

    def prepend(<<string::binary>>, nil), do: string

    def prepend(string, addition) do
      string |> to_string |> append(to_string(addition))
    end

    def strip(<<string::binary>>) do
      string |> String.trim
    end

    def lstrip(<<string::binary>>) do
      string |> String.trim_leading
    end

    def rstrip(<<string::binary>>) do
      string |> String.trim_trailing
    end

    def strip_newlines(<<string::binary>>) do
      string |> String.replace("\n", "") |> String.replace("\r", "")
    end

    def newline_to_br(<<string::binary>>) do
      string |> String.replace("\n", "<br />\n")
    end
    

    def split(<<string::binary>>, <<separator::binary>>) do
      String.split(string, separator)
    end

    def split(nil, _), do: []

    def slice(list, from, to) when is_list(list) do
      list |> Enum.slice(from, to)
    end

    def slice(<<string::binary>>, from, to) do
      string |> String.slice(from, to)
    end

    def slice(list, range) when is_list(list) and range == 0, do: list

    def slice(list, range) when is_list(list) and range > 0 do
      list |> Enum.slice(range, length(list))
    end

    def slice(list, range) when is_list(list) do
      len = length(list)
      list |> Enum.slice(len + range, len)
    end

    def slice(<<string::binary>>, range) when range == 0, do: string

    def slice(<<string::binary>>, range) when range > 0 do
      string |> String.slice(range, String.length(string))
    end

    def slice(<<string::binary>>, range) do
      len = String.length(string)
      string |> String.slice(len + range, len)
    end


    def slice(nil, _), do: ""

    def escape(input) when is_binary(input) do
      input |> HTML.html_escape
    end

    defdelegate h(input), to: __MODULE__, as: :escape

    def escape_once(input) when is_binary(input) do
      input |> HTML.html_escape_once
    end

    def strip_html(nil), do: ""
    
    def strip_html(input) when is_binary(input) do
      input
        |> String.replace(~r/<script.*?<\/script>/m, "") 
        |> String.replace(~r/<!--.*?-->/m, "")
        |> String.replace(~r/<style.*?<\/style>/m, "")
        |> String.replace(~r/<.*?>/m, "")
    end

    def url_encode(input) when is_binary(input) do
      input |> URI.encode_www_form
    end

    def url_encode(nil), do: nil

    defp to_iterable(input) when is_list(input) do
      case List.first(input) do
        first when is_number(first) ->
          input |> List.flatten
        first when is_nil(first) -> []
        _ -> [input]
      end
    end

    defp to_iterable(input) do
      # input when is_map(input) -> [input]
      # input when is_tuple(input) -> input 
      List.wrap(input)
    end

    defp to_number(input) when is_number(input), do: input

    defp to_number(input) when is_binary(input) do
      case Integer.parse(input) do
        {integer, ""} -> integer
        :error -> 0
        {integer, remainder} ->
          case Float.parse(input) do
            {_, float_remainder} when float_remainder == remainder ->
              integer
            {float, _} -> float
          end
      end
    end

    defp get_int_and_counter(input) when is_integer(input), do: {input, 0}

    defp get_int_and_counter(input) when is_number(input) do
      {_, remainder} = input |> Float.to_string |> Integer.parse
      len = String.length(remainder) -1
      new_value = (input * :math.pow(10, len)) |> Float.round |> trunc
      {new_value, len}
    end

    defp get_int_and_counter(input) do
      input |> to_number |> get_int_and_counter
    end

  end

  def parse(<<markup::binary>>) do
    [name|filters] = Regex.scan(Liquid.filter_parser, markup)
      |> List.flatten
      |> Enum.filter(&(&1 != "|"))
      |> Enum.map(&String.strip/1)
    filters = Enum.map(filters, fn(markup) ->
      [[_, filter]|_] = Regex.scan(~r/\s*(\w+)/, markup)
      args = Liquid.filter_arguments
        |> Regex.scan(markup)
        |> List.flatten
        |> Liquid.List.even_elements

      [String.to_atom(filter), args]
    end)
    [name|filters]
  end

  def filter([], value), do: value
  def filter([filter|rest], value) do
    [name, args] = filter
    args = Enum.map(args, fn(arg) ->
      Regex.replace(Liquid.quote_matcher, arg, "")
    end)
    ret  = apply(Functions, name, [value|args])
    filter(rest, ret)
  end

  def filter(a, b, _) when a == [] do
    filter(a, b)
  end

  def filter([head|tail], b, context) do
    case context.assigns do
      assigns when assigns == %{} ->
        filter([head|tail], b)
      assigns ->
        [name, args] = head
        args = Enum.map(args, fn(arg) ->
          cond do
            assigns |> Map.has_key?(arg) -> "#{assigns[arg]}"
            true -> arg
          end
        end)
        filter([[name, args] | tail], b)
    end
  end

end
