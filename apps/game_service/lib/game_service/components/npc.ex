defmodule GameService.NPCComponents do
  @moduledoc """
  TODO: Documentation for GameService.NPCComponents
  """

  defmodule NpcComponent do
    use ElvenGard.ECS.Component, state: [:name, :vnum]
  end

  defmodule QuestComponent do
    use ElvenGard.ECS.Component, state: [:dialog_id]
  end
end
