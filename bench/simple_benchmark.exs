Liquid.start()

markup = File.read!("./bench/simple.liquid")

Benchee.run(%{"parse:" => fn ->
               markup
               |> Liquid.Template.parse()
             end,
              "parse and render:" => fn ->
                markup
                |> Liquid.Template.parse()
                |> Liquid.Template.render()
              end},
  warmup: 5,
  time: 60
)
