defmodule GameService.NPCComponents do
  @moduledoc """
  TODO: Documentation for GameService.NPCComponents
  """

  defmodule NpcComponent do
    use ElvenGard.ECS.Component, state: [:vnum]
  end

  defmodule DialogComponent do
    use ElvenGard.ECS.Component, state: [:dialog_id]
  end

  defmodule EffectComponent do
    use ElvenGard.ECS.Component, state: [:delay]
  end

  defmodule QuestComponent do
    use ElvenGard.ECS.Component, state: [:dialog_id]
  end

  defmodule ShopComponent do
    use ElvenGard.ECS.Component, state: [:name, :type, :tabs]
  end
end
