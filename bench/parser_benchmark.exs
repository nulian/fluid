Liquid.start()

complex = File.read!("test/templates/complex/01/input.liquid")

middle = """
  <h1>{{ product.name }}</h1>
  <h2>{{ product.price }}</h2>
  <h2>{{ product.price }}</h2>
  {% comment %}This is a commentary{% endcomment %}
  {% raw %}This is a raw tag{% endraw %}
  {% for item in array %} Repeat this {% else %} Array Empty {% endfor %}
"""

simple = """
  {% for item in array %} Repeat this {% else %} Array Empty {% endfor %}
"""

empty = ""

templates = [complex: complex, middle: middle, simple: simple, empty: empty]

time = DateTime.to_string(DateTime.utc_now())

Enum.each(templates,
  fn {name, template} ->
    IO.puts "running: #{name}"
    Benchee.run(
      %{
        "#{name}-regex" => fn -> Liquid.Template.old_parse(template) end,
        "#{name}-nimble-with-translate" => fn -> Liquid.Template.parse(template) end,
        "#{name}-nimble" => fn -> Liquid.NimbleParser.parse(template) end
      },
      warmup: 5,
      time: 60,
      formatters: [
        Benchee.Formatters.Console,
        Benchee.Formatters.CSV
      ],
      formatter_options: [csv: [file: "bench/results/parser-benchmarks-#{time}.csv"]]
    )
  end
)

