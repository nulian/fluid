defmodule Liquid.Test.Integration.CasesTest do
  use ExUnit.Case, async: true
  import Liquid.Helpers

  @cases_dir "test/integration/cases"
  @levels ["simple", "medium", "complex"]
  @data "#{@cases_dir}/db.json"
        |> File.read!()
        |> Poison.decode!()

  # for level <- @levels do
  #   @level level
  #   test_cases = File.ls!("#{@cases_dir}/#{@level}")
  #   for test_case <- test_cases do
  #     test "case #{@level} - #{test_case}" do
  #       input_liquid = File.read!("#{@cases_dir}/#{@level}/#{unquote(test_case)}/input.liquid")
  #       expected_output = File.read!("#{@cases_dir}/#{@level}/#{unquote(test_case)}/output.html")
  #       liquid_output = render(input_liquid, @data)
  #       assert liquid_output == expected_output
  #     end
  #   end
  # end
end
