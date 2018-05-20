alias Liquid.Template
base_dir = "test/integration/cases"
data_file = "#{base_dir}/db.json"
data = data_file |> File.read!() |> Poison.decode!()

template =
  "#{base_dir}/#{folder}/input.liquid"
  |> File.read!()
  |> Template.parse()
  |> Template.render(data)
  |> elem(1)

File.write!("test/integration/cases/#{folder}/elixir-output.html", template)
folder = "complex/01"

System.cmd("ruby", [
  "test/integration/cases/liquid.rb",
  "test/integration/cases/#{folder}/input.liquid",
  data_file,
  "test/integration/cases/#{folder}/output.html"
])

template = "#{base_dir}/#{folder}/input.liquid" |> File.read!() |> Template.parse()
