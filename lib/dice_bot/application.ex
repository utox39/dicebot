defmodule DiceBot.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DiceBot.Consumer
    ]

    opts = [strategy: :one_for_one, name: DiceBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
