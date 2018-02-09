defmodule MemoryWeb.GameChannel do
  use MemoryWeb, :channel
  alias Memory.Game

  def join("game:", _payload, socket) do
    {:ok, Game.new(), socket}
  end

  def handle_in("item_clicked", %{"itemProps" => itemProps, "gameState" => gameState}, socket) do
    state = Game.handleItemClick(itemProps, gameState, socket)
    {:reply, {:ok, state}, socket}
  end

  def handle_in("game_reset", _payload, socket) do
    state = Game.handleGameReset()
    {:reply, {:ok, state}, socket}
  end

  def handle_info(:enable, socket) do
    IO.puts("HANDLE_INFO ...")
    broadcast!(socket, "enable", %{})
    {:noreply, socket}
  end

  def handle_in("enable", gameState, socket) do
    IO.puts("ENABLE ...")
    gameSate = Map.put(gameState, "isEnabled", true)
    Game.updateEnabled(gameSate)
    {:reply, {:ok, gameState}, socket}
  end

  # TODO authorize
end
