defmodule ElvenViews.LoginPackets.NsTeSTPacketTest do
  use PacketCase, async: true

  alias ElvenViews.LoginPackets.NsTeSTPacket
  alias ElvenViews.LoginPackets.NsTeST.Channel

  ## Tests

  describe "serialize/2" do
    test "with empty channel list" do
      mock = nstest_mock([])
      packet = serialize_structure(mock)

      assert is_list(packet)
      assert packet_index(packet, 0) == "NsTeST"
      assert packet_index(packet, 1) == structure_default(mock, :region)
      assert packet_index(packet, 2) == mock.username
      assert packet_index(packet, 3) == structure_default(mock, :auth_type)
      assert packet_index(packet, 4) == structure_default(mock, :server1)
      assert packet_index(packet, 5) == structure_default(mock, :server2)
      assert packet_index(packet, 6) == structure_default(mock, :server3)
      assert packet_index(packet, 7) == structure_default(mock, :server4)
      assert packet_index(packet, 8) == structure_default(mock, :server5)
      assert packet_index(packet, 9) == structure_default(mock, :server6)
      assert packet_index(packet, 10) == structure_default(mock, :unused_servers)
      assert packet_index(packet, 11) == 0
      assert packet_index(packet, 12) == mock.encryption_key
      assert packet_index(packet, 13) == "-1"
      assert packet_index(packet, 14) == "-1:-1:-1:10000.10000.1"
    end

    test "with non empty channel list" do
      channel = channel_mock()
      packet = [channel, channel] |> nstest_mock() |> serialize_structure()

      expected = serialize_structure(channel) <> " " <> serialize_structure(channel)
      assert packet_index(packet, 13) == expected
    end
  end

  ## Helpers

  defp nstest_mock(server_list) do
    %NsTeSTPacket{
      encryption_key: 132,
      username: "admin",
      server_list: server_list
    }
  end

  defp channel_mock() do
    %Channel{
      id: 1,
      world_id: 1,
      world_name: "ElvenGard",
      ip: "127.0.0.1",
      port: 4000,
      population: 0
    }
  end
end
