defmodule Memory.Game do
  use MemoryWeb, :channel
  alias Memory.MemoryAgent

  def new() do
    %{
      "clickCount" => 0,
      "isSecondClick" => false,
      "prevItemProps" => nil,
      "isEnabled" => true,
      "itemPropsMap" => newPropsMap()
    }
  end

  def handleItemClick(itemProps, gameState, socket) do
    prevProps = gameState["prevItemProps"]
    clickCount = gameState["clickCount"]
    itemProps = Map.put(itemProps, "isHidden", false)
    gameState = Map.put(gameState, "clickCount", clickCount + 1)
    gameState = updateItem(itemProps, gameState)
    # TODO game name
    MemoryAgent.save("foo", %{gameState: gameState, itemProps: itemProps})

    if gameState["isSecondClick"] do
      IO.inspect(gameState)

      if itemProps["value"] == prevProps["value"] do
        itemProps = Map.put(itemProps, "isMatched", true)
        prevProps = Map.put(prevProps, "isMatched", true)
        gameState = updateItem(itemProps, gameState)
        gameState = updateItem(prevProps, gameState)
        MemoryAgent.save("foo", %{gameState: gameState, itemProps: itemProps})
      else
        gameState = Map.put(gameState, "isEnabled", false)
        MemoryAgent.save("foo", %{gameState: gameState, itemProps: itemProps})
        MemoryAgent.schedule_work(%{name: "foo", socket: socket})
      end
    end

    gameState = Map.put(gameState, "prevItemProps", itemProps)
    gameState = Map.put(gameState, "isSecondClick", !gameState["isSecondClick"])
    MemoryAgent.save("foo", %{gameState: gameState, itemProps: itemProps})
    # TODO TODO TODO
    gameState
  end

  # update the isEnabled flag for each item
  def updateEnabled(gameState) do
    IO.puts("UPDATE ENABLED ...")
    propsMap = gameState["itemPropsMap"]
    updatedProps = helpUpdateEnabled(15, propsMap, gameState["isEnabled"])
    ("UPDATE ENABLED ..." <> Kernel.inspect(updatedProps)) |> IO.inspect()
    Map.put(gameState, "itemPropsMap", updatedProps)
  end

  # recurs through all of the item IDs,
  defp helpUpdateEnabled(id, propsMap, flag) do
    if id < 0 do
      propsMap
    else
      props = propsMap["#{id}"]
      props = Map.put(props, "isEnabled", flag)
      propsMap = Map.put(propsMap, "id", props)
      helpUpdateEnabled(id - 1, propsMap, flag)
    end
  end

  # updates an item and returns a new game state
  def updateItem(itemProps, gameState) do
    propsMap = gameState["itemPropsMap"]
    propsMap = Map.put(propsMap, itemProps["id"], itemProps)
    Map.put(gameState, "itemPropsMap", propsMap)
  end

  def handleGameReset() do
    new()
  end

  defp newPropsMap() do
    newLetterArray() |> newPropsMap(15, %{})
  end

  defp newLetterArray() do
    ~w(A B C D E F G H A B C D E F G H) |> Enum.shuffle()
  end

  defp newPropsMap(letters, countdown, acc) do
    if countdown < 0 do
      acc
    else
      [val | letters] = letters

      acc =
        Map.put_new(acc, "#{countdown}", %{
          "id" => countdown,
          "isEnabled" => true,
          "isHidden" => true,
          "isMatched" => false,
          "value" => val
        })

      newPropsMap(letters, countdown - 1, acc)
    end
  end
end
