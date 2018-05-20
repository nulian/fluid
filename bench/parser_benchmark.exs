Liquid.start()

template = """
  {% decrement product.price %}
  <h1>{{ product.name }}</h1>
  <h2>{{ product.price }}</h2>
  {% increment product.price %}
  <h2>{{ product.price }}</h2>
  {% comment %}This is a commentary{% endcomment %}
  {% raw %}This is a raw tag{% endraw %}
  {% for item in array %} Repeat this {% else %} Array Empty {% endfor %}
"""
template = """
  {% for item in array %} Repeat this {% else %} Array Empty {% endfor %}
"""

time = DateTime.to_string(DateTime.utc_now())

Benchee.run(
  %{
    nimble: fn -> Liquid.NimbleParser.parse(template) end,
    regex: fn -> Liquid.Template.parse(template) end
  },
  warmup: 5,
  time: 60,
  formatters: [
    Benchee.Formatters.Console,
    Benchee.Formatters.CSV
  ],
  formatter_options: [csv: [file: "bench/results/parser-benchmarks-#{time}.csv"]]
)
