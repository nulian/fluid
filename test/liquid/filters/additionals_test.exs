defmodule Liquid.Filters.AdditionalsTest do
  use ExUnit.Case
  use Timex
  doctest Liquid.Filters.Additionals

  alias Liquid.Filters.Additionals

  setup_all do
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test :default do
    assert "foo" == Additionals.default("foo", "bar")
    assert "bar" == Additionals.default(nil, "bar")
    assert "bar" == Additionals.default("", "bar")
    assert "bar" == Additionals.default(false, "bar")
    assert "bar" == Additionals.default([], "bar")
    assert "bar" == Additionals.default({}, "bar")
  end

  test :date do
    assert "May" == Additionals.date(~N[2006-05-05 10:00:00], "%B")
    assert "June" == Additionals.date(Timex.parse!("2006-06-05 10:00:00", "%F %T", :strftime), "%B")
    assert "July" == Additionals.date(~N[2006-07-05 10:00:00], "%B")

    assert "May" == Additionals.date("2006-05-05 10:00:00", "%B")
    assert "June" == Additionals.date("2006-06-05 10:00:00", "%B")
    assert "July" == Additionals.date("2006-07-05 10:00:00", "%B")

    assert "2006-07-05 10:00:00" == Additionals.date("2006-07-05 10:00:00", "")
    assert "2006-07-05 10:00:00" == Additionals.date("2006-07-05 10:00:00", "")
    assert "2006-07-05 10:00:00" == Additionals.date("2006-07-05 10:00:00", "")
    assert "2006-07-05 10:00:00" == Additionals.date("2006-07-05 10:00:00", nil)

    assert "07/05/2006" == Additionals.date("2006-07-05 10:00:00", "%m/%d/%Y")

    assert "07/16/2004" == Additionals.date("Fri Jul 16 01:00:00 2004", "%m/%d/%Y")

    assert "#{Timex.today().year}" == Additionals.date("now", "%Y")
    assert "#{Timex.today().year}" == Additionals.date("today", "%Y")

    assert nil == Additionals.date(nil, "%B")
  end
end
