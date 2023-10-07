defmodule GameService.NPCComponents do
  @moduledoc """
  TODO: Documentation for GameService.NPCComponents
  """

  defmodule NpcComponent do
    use ElvenGard.ECS.Component, state: [:name, :vnum]
  end
end
