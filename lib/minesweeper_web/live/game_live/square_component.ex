defmodule MinesweeperWeb.GameLive.SquareComponent do
  use MinesweeperWeb, :live_component

  def show(%{revealed?: false, marked?: false}), do: ""

  def show(%{revealed?: false, marked?: true}), do: "flag"

  def show(%{revealed?: true, value: :mine}), do: "mine!"

  def show(%{revealed?: true, value: n}), do: n
end
