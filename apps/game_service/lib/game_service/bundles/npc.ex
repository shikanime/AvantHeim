defmodule GameService.NpcBundle do
  @moduledoc """
  TODO: Documentation for GameService.NpcBundle
  """

  alias __MODULE__
  alias ElvenGard.ECS.{Component, Entity}
  alias GameService.EntityComponents, as: E
  alias GameService.NpcComponents, as: M

  ## NpcBundle structures (for outside use)

  @enforce_keys [
    :id,
    :npc,
    :position,
    :speed,
    :direction
  ]
  defstruct @enforce_keys

  @typep component(module) :: module | :unset

  @type t :: %NpcBundle{
          id: pos_integer(),
          # Basics components
          npc: component(M.NpcComponent),
          position: component(E.PositionComponent),
          speed: component(E.SpeedComponent),
          direction: component(E.DirectionComponent)
        }

  ## Public API

  @spec specs(map()) :: ElvenGard.ECS.Entity.spec()
  def specs(attrs) do
    id = Map.fetch!(attrs, :id)

    Entity.entity_spec(
      id: {:npc, id},
      components: [
        # Basics components
        {M.NpcComponent, npc_specs(attrs)},
        {E.PositionComponent, position_specs(attrs)},
        {E.LevelComponent, level_specs(attrs)},
        {E.SpeedComponent, speed_specs(attrs)},
        {E.DirectionComponent, direction_specs(attrs)}
      ]
    )
  end

  @doc """
  This function can be use to create a NpcBundle from an Entity an a list of components
  """
  @spec load(Entity.t(), [Component.t()]) :: t()
  def load(%Entity{id: {:npc, id}}, components) when is_list(components) do
    # mapping = Enum.group_by(components, & &1.__struct__)
    mapping = Map.new(components, &{&1.__struct__, &1})

    %NpcBundle{
      id: id,
      # Basics components
      npc: Map.fetch!(mapping, M.NpcComponent),
      position: Map.fetch!(mapping, E.PositionComponent),
      speed: Map.fetch!(mapping, E.SpeedComponent),
      direction: Map.fetch!(mapping, E.DirectionComponent)
    }
  end

  @doc """
  This function can be use to create a NpcBundle from an Entity an a list of components

  Unlike `load/2`, you don't have to provide all components.  
  Components not found will have the value `:unset`

  NOTE: You must verify that you have the required components in your system.
  """
  @spec preload(Entity.t(), [Component.t()]) :: t()
  def preload(%Entity{id: {:npc, id}}, components) when is_list(components) do
    # mapping = Enum.group_by(components, & &1.__struct__)
    mapping = Map.new(components, &{&1.__struct__, &1})

    %NpcBundle{
      id: id,
      # Basics components
      npc: Map.get(mapping, M.NpcComponent, :unset),
      position: Map.get(mapping, E.PositionComponent, :unset),
      speed: Map.get(mapping, E.SpeedComponent, :unset),
      direction: Map.get(mapping, E.DirectionComponent, :unset)
    }
  end

  ## Getters

  def vnum(%NpcBundle{} = npc) do
    case npc.npc do
      :unset -> raise ArgumentError, "you must fetch the Npc.NpcComponent first"
      npc -> npc.vnum
    end
  end

  def map_ref(%NpcBundle{} = npc) do
    case npc.position do
      :unset -> raise ArgumentError, "you must fetch the Entity.PositionComponent first"
      position -> position.map_ref
    end
  end

  def map_x(%NpcBundle{} = npc) do
    case npc.position do
      :unset -> raise ArgumentError, "you must fetch the Entity.PositionComponent first"
      position -> position.map_x
    end
  end

  def map_y(%NpcBundle{} = npc) do
    case npc.position do
      :unset -> raise ArgumentError, "you must fetch the Entity.PositionComponent first"
      position -> position.map_y
    end
  end

  def name(%NpcBundle{} = npc) do
    case npc.npc do
      :unset -> raise ArgumentError, "you must fetch the Npc.NpcComponent first"
      npc -> npc.name
    end
  end

  def spawn_effect(%NpcBundle{} = npc) do
    case npc.npc do
      :unset -> raise ArgumentError, "you must fetch the Npc.NpcComponent first"
      npc -> npc.spawn_effect
    end
  end

  def direction(%NpcBundle{} = npc) do
    case npc.direction do
      :unset -> raise ArgumentError, "you must fetch the Entity.DirectionComponent first"
      direction -> direction.value
    end
  end

  ## Components specs

  defp npc_specs(%{vnum: vnum}) do
    [vnum: vnum, spawn_effect: :falling]
  end

  defp position_specs(%{map_id: map_id, map_x: map_x, map_y: map_y} = attrs) do
    map_ref = Map.get(attrs, :map_ref, map_id)
    [map_id: map_id, map_ref: map_ref, map_x: map_x, map_y: map_y]
  end

  defp level_specs(_attrs) do
    # FIXME: Harcoded value
    [value: 3]
  end

  defp speed_specs(attrs) do
    # FIXME: Hardcoded value, now sure if it's the best place
    [value: Map.get(attrs, :speed, 15)]
  end

  defp direction_specs(attrs) do
    [value: Map.get(attrs, :direction, :south)]
  end
end
