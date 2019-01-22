defmodule Liquid.Translators.Tags.CaseTest do
  use ExUnit.Case

  import Liquid.Helpers

  test "case translate new AST to old AST" do
    [
      {"{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
       %{"condition" => 2}},
      {"{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
       %{"condition" => 1}},
      {"{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
       %{"condition" => 3}},
      {"{% case condition %}{% when \"string here\" %} hit {% endcase %}",
       %{"condition" => "string here"}},
      {"{% case condition %}{% when \"string here\" %} hit {% endcase %}",
       %{"condition" => "string here"}},
      {"{% case condition %}{% when 5 %} hit {% else %} else {% endcase %}",
       %{"condition" => "bad string here"}},
      {"{% case condition %}{% when 5 %} hit {% else %} else {% endcase %}", %{"condition" => 5}}
      # {"{% case condition %} {% when 5 %} hit {% else %} else {% endcase %}", %{"condition" => 6}},
      # {"{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{"a" => []}},
      # {"{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{"a" => [1]}},
      # {"{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{"a" => [1, 1]}},
      # {"{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{"a" => [1, 1, 1]}},
      # {"{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{"a" => [1, 1, 1, 1]}},
      # {"{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{"a" => [1, 1, 1, 1, 1]}},
      #########################################################################
      # {"{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}", %{"condition" => 2}},
      # {"{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}", %{"condition" => 2}},
      # {"{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}", %{"condition" => 2}},
      # {"{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}", %{"condition" => 2}},
      # {"{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}", %{"condition" => 2}},
      # {"{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}", %{"condition" => 2}},
      # {"{% case a.empty? %}{% when true %}true{% when false %}false{% else %}else{% endcase %}", %{"condition" => 2}},
      # {"{% case false %}{% when true %}true{% when false %}false{% else %}else{% endcase %}", %{"condition" => 2}},
      # {"{% case true %}{% when true %}true{% when false %}false{% else %}else{% endcase %}", %{"condition" => 2}},
      # {"{% case NULL %}{% when true %}true{% when false %}false{% else %}else{% endcase %}", %{"condition" => 2}},
      # {"{% case collection.handle %}{% when 'menswear-jackets' %}{% assign ptitle = 'menswear' %}{% when 'menswear-t-shirts' %}{% assign ptitle = 'menswear' %}{% else %}{% assign ptitle = 'womenswear' %}{% endcase %}{{ ptitle }}", %{"condition" => 2}}
    ]
    |> Enum.each(fn {markup, params} ->
      test_ast_translation(markup, params)
    end)
  end
end
