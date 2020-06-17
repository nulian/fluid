defmodule Liquid.Supervisor do
  @moduledoc """
  Supervisor for Liquid processes (currently empty)
  """
  use Supervisor

  @doc """
  Starts the liquid supervisor
  """
  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @doc """
  Actual supervisor init with no child processes to supervise yet
  """
  def init(:ok) do
    children = []
    supervise(children, strategy: :one_for_one)
  end
end
