defmodule Liquid.Dev.ErrorHandler do
  def handle(message, params \\ []) do
    case message do
      "not found" ->
        ~s(<div style="color: #856404; background-color: #fff3cd; border-color: #ffeeba; padding: .75rem 1.25rem; margin-bottom: 1rem; border: 1px solid transparent;
    border-radius: .25rem;margin-top: 1rem;">
            Trying to include missing file '#{Keyword.get(params, :name)}'
          </div>)

      error_message ->
        ~s(
          <div style="color: #856404; background-color: #fff3cd; border-color: #ffeeba; padding: .75rem 1.25rem; margin-bottom: 1rem; border: 1px solid transparent;
    border-radius: .25rem;margin-top: 1rem;">
          Errored while including template '"#{Keyword.get(params, :name)}"', error: "#{error_message}"
        </div>
        )
    end
  end
end

defmodule Liquid.Prod.ErrorHandler do
  def handle(_message, _params \\ []), do: ""
end
