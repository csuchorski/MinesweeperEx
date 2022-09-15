defmodule Minesweeper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MinesweeperWeb.Telemetry,
      {Phoenix.PubSub, name: Minesweeper.PubSub},
      MinesweeperWeb.Endpoint,
      {DynamicSupervisor, strategy: :one_for_one, name: Minesweeper.DynamicSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Minesweeper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MinesweeperWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
