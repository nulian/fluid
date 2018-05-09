Liquid.start()

template = """
  {% decrement product.price %}
  <h1>{{ product.name }}</h1>
  <h2>{{ product.price }}</h2>
  {% increment product.price %}
  <h2>{{ product.price }}</h2>
  {% comment %}This is a commentary{% endcomment %}
  {% raw %}This is a raw tag{% endraw %}
"""

time = DateTime.to_string(DateTime.utc_now())

Benchee.run(
  %{
    nimble: fn -> Liquid.NimbleParser.parse(template) end,
    regex: fn -> Liquid.Template.parse(template) end
  },
  warmup: 1,
  time: 5,
  formatters: [
    Benchee.Formatters.Console,
    Benchee.Formatters.CSV
  ],
  formatter_options: [csv: [file: "bench/results/parser-benchmarks-#{time}.csv"]]
)
