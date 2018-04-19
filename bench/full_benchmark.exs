Liquid.start()

path = "test/templates"
levels = ["simple", "medium", "complex"]

data =
  "#{path}/db.json"
  |> File.read!()
  |> Poison.decode!()

markup = File.read!("#{path}/simple/01/input.liquid")

parsed = Liquid.Template.parse(markup)

Benchee.run(%{"#{level} parse:" => fn ->
               Liquid.Template.parse(markup)
             end,
              "#{level} render:" => fn ->
                Liquid.Template.render(parsed, data)
              end},
  warmup: 2,
  time: 5
)
