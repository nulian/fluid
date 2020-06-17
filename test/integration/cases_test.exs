defmodule Liquid.Test.Integration.CasesTest do
  use ExUnit.Case, async: true
  import Liquid.Helpers

  @cases_dir "test/templates"
  @levels ["simple", "medium", "complex"]
  @data "#{@cases_dir}/db.json"
        |> File.read!()
        |> Jason.decode!()

  setup do
    start_supervised!({Liquid.Process, [name: :liquid]})
    :ok
  end

  for level <- @levels, test_case <- File.ls!("#{@cases_dir}/#{level}") do
    test "case #{level} - #{test_case}" do
      input_liquid =
        File.read!("#{@cases_dir}/#{unquote(level)}/#{unquote(test_case)}/input.liquid")

      expected_output =
        File.read!("#{@cases_dir}/#{unquote(level)}/#{unquote(test_case)}/output.html")

      liquid_output = render(:liquid, input_liquid, @data)
      assert liquid_output == expected_output
    end
  end
end
