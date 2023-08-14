defmodule LoginService.Endpoint.NetworkCodec do
  @moduledoc """
  TODO: LoginService.Endpoint.NetworkCodec
  """

  @behaviour ElvenGard.Network.NetworkCodec

  alias ElvenPackets.Client.LoginPackets
  alias LoginService.Endpoint.Cryptography

  @impl true
  def next(raw, _socket) do
    Cryptography.next(raw)
  end

  @impl true
  def deserialize(raw, socket) do
    decrypted = Cryptography.decrypt(raw, socket.assigns)
    [packet_id, rest] = String.split(decrypted, " ", parts: 2)
    LoginPackets.deserialize(packet_id, rest, socket)
  end

  @impl true
  def serialize(struct, socket) when is_struct(struct) do
    {packet_id, params} = struct.__struct__.serialize(struct)
    serialize([packet_id, params], socket)
  end

  def serialize(raw, _socket) when is_list(raw) do
    raw
    |> List.flatten()
    |> Enum.intersperse(" ")
    |> :erlang.list_to_binary()
    |> Cryptography.encrypt()
  end
end
