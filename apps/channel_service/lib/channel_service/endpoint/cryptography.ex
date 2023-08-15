defmodule ChannelService.Endpoint.Cryptography do
  @moduledoc """
  Cryptography for a NosTale channel endpoint.
  """

  import Bitwise, only: [band: 2, bxor: 2, bsr: 2, bnot: 1]

  ## Public API

  @doc """
  Decrypt the delimiter from a key.
  """
  @spec pack_delimiter(integer(), integer()) :: integer()
  def pack_delimiter(offset, mode) do
    case mode do
      0 -> 0xFF + offset
      1 -> 0xFF - offset
      2 -> bxor(0xFF + offset, 0xC3)
      3 -> bxor(0xFF - offset, 0xC3)
    end
  end

  @doc """
  Decrypt the offset from a key.
  """
  @spec cipher_offset(integer()) :: integer()
  def cipher_offset(key) do
    band(key, 0xFF)
  end

  @doc """
  Decrypt the mode from a key.
  """
  @spec cipher_mode(integer()) :: integer()
  def cipher_mode(key) do
    bsr(key, band(6, 3))
  end

  @doc """
  Get the next packet from a raw binary.

  ## Examples

      iex> ChannelService.Endpoint.Cryptography.next(<<198, 228, 203, 145, 70, 205, 214, 220, 208, 217, 208, 196, 7, 212, 73, 255, 208, 203, 222, 209, 215, 208, 210, 218, 193, 112, 67, 220, 208, 210, 63, 199, 228, 203, 161, 16, 72, 215, 214, 221, 200, 214, 200, 214, 248, 193, 160, 65, 218, 193, 224, 66, 241, 205, 199, 228, 203, 161, 16, 72, 215, 214, 221, 200, 214, 200, 214, 248, 193, 160, 65, 218, 193, 224, 66, 241, 205>>, %{delimiter: 0xFF})
      {<<198, 228, 203, 145, 70, 205, 214, 220, 208, 217, 208, 196, 7, 212, 73>>, <<208, 203, 222, 209, 215, 208, 210, 218, 193, 112, 67, 220, 208, 210, 63, 199, 228, 203, 161, 16, 72, 215, 214, 221, 200, 214, 200, 214, 248, 193, 160, 65, 218, 193, 224, 66, 241, 205, 199, 228, 203, 161, 16, 72, 215, 214, 221, 200, 214, 200, 214, 248, 193, 160, 65, 218, 193, 224, 66, 241, 205>>}
  """
  @spec next(binary(), map(), binary()) :: {binary() | nil, binary()}
  def next(raw, assigns, acc \\ <<>>)

  def next(<<>>, assigns, acc) do
    {acc, <<>>}
  end

  def next(<<c, rest::binary>>, assigns, acc) do
    if c == assigns.delimiter do
      {acc, rest}
    else
      next(rest, assigns, <<acc::binary, c>>)
    end
  end

  @permutations %{
    0 => " ",
    1 => "-",
    2 => ".",
    3 => "0",
    4 => "1",
    5 => "2",
    6 => "3",
    7 => "4",
    8 => "5",
    9 => "6",
    10 => "7",
    11 => "8",
    12 => "9",
    13 => "n"
  }

  @doc """
  Unpack a world packet.

  ## Examples

      iex> ChannelService.Endpoint.Cryptography.unpack(<<135, 141, 107, 177, 64>>)
      "49277 0"
  """
  @spec unpack(binary(), binary()) :: binary()
  def unpack(binary, acc \\ <<>>)

  def unpack(<<>>, acc) do
    acc
  end

  def unpack(<<flag, rest::binary>>, acc) do
    if 0x7A > flag do
      {pack, rest} = unpack_linear(rest, flag)
      unpack(rest, <<pack::binary, acc::binary>>)
    else
      {pack, rest} = unpack_compact(rest, band(flag, 0x7F))
      unpack(rest, <<pack::binary, acc::binary>>)
    end
  end

  defp unpack_compact(pack, flag) do
    len = min(byte_size(pack), flag)
    data = unpack_compact_payload(pack, len)
    {data, :binary.part(pack, {len, byte_size(pack) - len})}
  end

  defp unpack_compact_payload(<<c>>, _len) do
    h = bsr(c, 4)
    l = band(c, 0xF)

    case {h != 0 and h != 0xF, l != 0 and l != 0xF} do
      {true, false} ->
        Map.get(@permutations, h - 1)

      {true, true} ->
        Map.get(@permutations, h - 1) <> Map.get(@permutations, l - 1)

      {false, true} ->
        Map.get(@permutations, l - 1)
    end
  end

  defp unpack_compact_payload(payload, len) do
    for <<c <- :binary.part(payload, {0, len})>>, into: <<>> do
      unpack_compact_payload(<<c>>, len)
    end
  end

  defp unpack_linear(pack, flag) do
    len = min(byte_size(pack), flag)
    data = unpack_linear_payload(pack, len)
    {data, :binary.part(pack, {len, byte_size(pack) - len})}
  end

  defp unpack_linear_payload(<<c>>, len) do
    <<bxor(c, 0xFF)>>
  end

  defp unpack_linear_payload(payload, len) do
    for <<c <- :binary.part(payload, {0, len})>>, into: <<>> do
      unpack_linear_payload(<<c>>, len)
    end
  end

  @doc """
  Encrypt a world packet.

  ## Examples

      iex> ChannelService.Endpoint.Cryptography.encrypt("foo")
      <<3, 153, 144, 144, 255>>
  """
  @spec encrypt(binary) :: binary
  def encrypt(packet) do
    <<encrypt_payload(packet)::binary, 0xFF>>
  end

  defp encrypt_payload(payload) do
    bytes = payload |> :binary.bin_to_list() |> Enum.with_index()
    len = length(bytes)

    for {c, i} <- bytes, into: <<>> do
      if rem(i, 0x7E) != 0 do
        <<bnot(c)>>
      else
        remaining = if len - i > 0x7E, do: 0x7E, else: len - i
        <<remaining, bnot(c)>>
      end
    end
  end

  @doc """
  Decrypt a channel packet.

  ## Examples
      iex> ChannelService.Endpoint.Cryptography.decrypt(<<198, 228, 203, 145, 70, 205, 214, 220, 208, 217, 208, 196, 7, 212, 73, 255, 208, 203, 222, 209, 215, 208, 210, 218, 193, 112, 67, 220, 208, 210, 63, 199, 228, 203, 161, 16, 72, 215, 214, 221, 200, 214, 200, 214, 248, 193, 160, 65, 218, 193, 224, 66, 241, 205>>, %{})
      "7391784-.37:83898 868 71;481.6; 8 788;8-848 8.877-2 .0898 8.. 7491785-  .584838:75837583:57-5 .-877-9 ..:-7:"

      iex> ChannelService.Endpoint.Cryptography.decrypt(<<159, 172, 100, 160, 99, 235, 103, 120, 99, 14>>, %{})
      "5 59115 1098142510;;"
  """
  @spec decrypt(binary, map) :: binary
  def decrypt(binary, assigns) when is_map_key(assigns, :offset) and is_map_key(assigns, :mode) do
    decrypt_channel(binary, assigns)
  end

  def decrypt(binary, assigns) do
    decrypt_session(binary, assigns)
  end

  defp decrypt_session(<<>>, _assigns) do
    <<>>
  end

  defp decrypt_session(<<c>>, _assigns) do
    first_byte = c - 0xF
    second_byte = band(first_byte, 0xF0)
    first_key = first_byte - second_byte
    second_key = bsr(second_byte, 0x4)

    for key <- [second_key, first_key], into: <<>> do
      case key do
        0 -> <<0x20>>
        1 -> <<0x20>>
        2 -> <<0x2D>>
        3 -> <<0x2E>>
        _ -> <<0x2C + key>>
      end
    end
  end

  defp decrypt_session(packet, assigns) do
    for <<c <- packet>>, into: <<>>, do: decrypt_session(<<c>>, assigns)
  end

  defp decrypt_channel(c, assigns) do
    case assigns.mode do
      0 -> <<c - assigns.offset>>
      1 -> <<c + assigns.offset>>
      2 -> <<bxor(c - assigns.offset, 0xC3)>>
      3 -> <<bxor(c + assigns.offset, 0xC3)>>
    end
  end
end
