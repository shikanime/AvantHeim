Code.require_file("../fixtures/test_packet.exs", __DIR__)

defmodule ElvenViews.SerializablePacketTest do
  use PacketCase, async: true

  import ExUnit.CaptureIO
  import ElvenCore.Socket.Serializer, only: [serialize_term: 2]

  alias MyApp.{SerializableTestStruct, TestPacket}

  ## Tests

  describe "defpacket/2" do
    test "define a structure" do
      assert function_exported?(TestPacket, :__struct__, 1)
    end

    test "define typespec for the structure" do
      code = """
      defmodule MyApp.TestPacket2 do
        use ElvenViews.SerializablePacket

        require MyApp.TestPacketEnums
        
        alias MyApp.SerializableTestStruct
        alias MyApp.TestPacketEnums
        
        # Little trick to get module bytecode
        # I don't know if there is a better way to do that
        # Maybe use Compiler Tracing ?
        @after_compile TypeInspector
        
        defpacket "test" do
          field :id, :pos_integer
          field :id2, :non_neg_integer, default: 0
          field :id3, :integer, default: -123
          field :enabled, :boolean
          field :message, :string
          field :type, :enum, values: TestPacketEnums.type(:__enumerators__)
          field :my_struct, SerializableTestStruct
          field :my_list, :list, type: SerializableTestStruct, default: []
        end
      end
      """

      log = capture_io(fn -> Code.compile_string(code) end)

      assert log =~ "t() :: %MyApp.TestPacket2{"
      assert log =~ "id: pos_integer()"
      assert log =~ "id2: non_neg_integer()"
      assert log =~ "id3: integer()"
      assert log =~ "enabled: boolean()"
      assert log =~ "message: String.t()"
      assert log =~ "type: ElvenViews.SerializablePacket.enum()"
      assert log =~ "my_struct: MyApp.SerializableTestStruct.t()"
      assert log =~ "my_list: [MyApp.SerializableTestStruct.t()]"
    end
  end

  describe "__using__/1" do
    test "define behaviour ElvenCore.SerializableStruct" do
      mock = test_packet_mock()

      iodata = TestPacket.serialize(mock, [])
      assert packet_index(iodata, 0) == TestPacket.__header__()
      assert packet_index(iodata, 1) == mock.id
      assert packet_index(iodata, 2) == structure_default(mock, :id2)
      assert packet_index(iodata, 3) == structure_default(mock, :id3)
      assert packet_index(iodata, 4) == mock.enabled
      assert packet_index(iodata, 5) == structure_enum_value(mock, :type)
      assert packet_index(iodata, 6) == mock.message
      assert %SerializableTestStruct{} = packet_index(iodata, 7)

      expected = "test 123 0 -123 1 1 This is a message 123-789"
      assert ^expected = serialize_term(mock, [])
    end
  end

  ## Private helpers

  defp test_packet_mock(attrs \\ %{}) do
    Map.merge(
      %TestPacket{
        id: 123,
        enabled: true,
        type: :admin,
        message: "This is a message",
        my_struct: %MyApp.SerializableTestStruct{key2: 789}
      },
      attrs
    )
  end
end
