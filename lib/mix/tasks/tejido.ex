defmodule Mix.Tasks.Tejido do
  @moduledoc """
  Runs Tejido REPL to send patterns to Pure Data.

  ## Usage

      $ mix tejido [PORT]

  PORT defaults to 7000.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    port = case args do
      [port_str] -> String.to_integer(port_str)
      _ -> 7000
    end

    # Start applications
    Application.ensure_all_started(:tejido)

    # Start the REPL
    Tejido.PDSender.start(port)
  end
end