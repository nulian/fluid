Liquid.start()

defmodule Random do
  def render(output, tag, context) do
    {"MyCustomTag Results...output:#{output} tag:#{tag}", context}
  end
end

defmodule RandomBlock do
  def render(output, tag, context) do
    {"MyCustomBlock Results...output:#{output} tag:#{tag}", context}
  end
end


Liquid.Registers.register("random", Random, Liquid.Tag)
Liquid.Registers.register("randomblock", RandomBlock, Liquid.Block)

custom_tag = "{% random 5 %}"
custom_block = "{% randomblock 5 %} This is a Random Number: ^^^ {% endrandomblock %}"

templates = [
  custom_tag: custom_tag,
  custom_block: custom_block
]

benchmarks =
  for {name, template} <- templates, into: %{} do
    {name, fn -> Liquid.Parser.parse(template) end}
  end

Benchee.run(
  benchmarks,
  warmup: 5,
  time: 20,
  print: [
    benchmarking: true,
    configuration: false,
    fast_warning: false
  ],
  console: [
    comparison: false
  ]
)
