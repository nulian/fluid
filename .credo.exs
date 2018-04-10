%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/"]
      }
    },
    strict: true,
    checks: [
      {Credo.Check.Readability.MaxLineLength, max_length: 120}
    ]
  ]
}
