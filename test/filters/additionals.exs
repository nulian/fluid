defmodule Liquid.Filters.AdditionalsTest do
  use ExUnit.Case
  use Timex
  doctest Liquid.Filters.Additionals

  alias Liquid.{Filters, Template, Variable}
  alias Liquid.Filters.{Additionals, HTML, List, Math, String}

  setup_all do
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test :default do
    assert "foo" == Functions.default("foo", "bar")
    assert "bar" == Functions.default(nil, "bar")
    assert "bar" == Functions.default("", "bar")
    assert "bar" == Functions.default(false, "bar")
    assert "bar" == Functions.default([], "bar")
    assert "bar" == Functions.default({}, "bar")
  end

  test :date do
    assert "May" == Functions.date(~N[2006-05-05 10:00:00], "%B")
    assert "June" == Functions.date(Timex.parse!("2006-06-05 10:00:00", "%F %T", :strftime), "%B")
    assert "July" == Functions.date(~N[2006-07-05 10:00:00], "%B")

    assert "May" == Functions.date("2006-05-05 10:00:00", "%B")
    assert "June" == Functions.date("2006-06-05 10:00:00", "%B")
    assert "July" == Functions.date("2006-07-05 10:00:00", "%B")

    assert "2006-07-05 10:00:00" == Functions.date("2006-07-05 10:00:00", "")
    assert "2006-07-05 10:00:00" == Functions.date("2006-07-05 10:00:00", "")
    assert "2006-07-05 10:00:00" == Functions.date("2006-07-05 10:00:00", "")
    assert "2006-07-05 10:00:00" == Functions.date("2006-07-05 10:00:00", nil)

    assert "07/05/2006" == Functions.date("2006-07-05 10:00:00", "%m/%d/%Y")

    assert "07/16/2004" == Functions.date("Fri Jul 16 01:00:00 2004", "%m/%d/%Y")

    assert "#{Timex.today().year}" == Functions.date("now", "%Y")
    assert "#{Timex.today().year}" == Functions.date("today", "%Y")

    assert nil == Functions.date(nil, "%B")

    # Timex already uses UTC
    # with_timezone("UTC") do
    #   assert "07/05/2006" == Functions.date(1152098955, "%m/%d/%Y")
    #   assert "07/05/2006" == Functions.date("1152098955", "%m/%d/%Y")
    # end
  end

#Helper Test Builder Functions
  defp assert_template_result(expected, markup, assigns \\ %{})

  defp assert_template_result(expected, markup, assigns) do
    assert_result(expected, markup, assigns)
  end

  defp assert_result(expected, markup, assigns) do
    template = Template.parse(markup)

    with {:ok, result, _} <- Template.render(template, assigns) do
      assert result == expected
    else
      {:error, message, _} ->
        assert message == expected
    end
  end

end