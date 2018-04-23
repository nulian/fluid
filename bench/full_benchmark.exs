Liquid.start()

path = "test/templates"
levels = ["simple", "medium", "complex"]

data =
  "#{path}/db.json"
  |> File.read!()
  |> Poison.decode!()

levels_map =
  for level <- levels,
    test_case <- File.ls!("#{path}/#{level}"),
    into: %{} do
      markup = File.read!("#{path}/#{level}/#{test_case}/input.liquid")
      parsed = Liquid.Template.parse(markup)
      {level, %{test_case => %{parse: markup, render: parsed}}}
  end

create_phase = fn cases, phase ->
  fn ->
    for {_, %{^phase => param}} <- cases do
      args = if phase == :render, do: [param, data], else: [param]
      apply(Liquid.Template, phase, args)
    end
  end
end

for phase <- [:parse, :render] do
  time = DateTime.to_string(DateTime.utc_now())
  benchmark = for {level, cases} <- levels_map, into: %{} do
    {"#{level} #{phase}", create_phase.(cases, phase)}
  end

  Benchee.run(benchmark, warmup: 5, time: 60,
    formatters: [
      Benchee.Formatters.CSV,
      Benchee.Formatters.Console
    ],
    formatter_options: [csv: [file: "bench/results/#{phase}-#{time}.csv"]])
end
