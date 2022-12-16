defmodule ChunkPNGTest do
  use ExUnit.Case
  # doctest ChunkPNG

  alias ChunkPNG.Chunk
  alias ChunkPNG.TEXT

  @png "test/elixir.png"

  describe "ChunkPNG" do
    test "parse_file!/1" do
      assert {:ok, _} = ChunkPNG.parse_file!(@png)
    end

    test "parse_buffer/1 round trip write_buffer/1" do
      input = File.read!(@png)
      {:ok, zipper} = ChunkPNG.parse_buffer(input)
      output = ChunkPNG.write_buffer(zipper)
      assert input == output
    end
  end

  describe "ChunkPNG.Chunk.crc/2" do
    test "IHDR" do
      assert 3_947_343_424 == Chunk.crc("IHDR", <<0, 0, 1, 194, 0, 0, 0, 188, 8, 6, 0, 0, 0>>)
    end
  end

  describe "ChunkPNG.TEXT" do
    test "requires non-empty key" do
      assert_raise ArgumentError, fn ->
        TEXT.new!("", "VALUE")
      end
    end

    test "requires key shorter than 80 chars" do
      long_key = String.pad_leading("k", 80, "x")

      assert_raise ArgumentError, fn ->
        TEXT.new!(long_key, "VALUE")
      end
    end

    test "NULL removed from key" do
      assert %{raw: raw, length: 4} = ChunkPNG.TEXT.new!("k\0y", "v")
      assert {8, 4} == :binary.match(raw, <<?k, ?y, 0, ?v>>)
    end

    test "NULL removed from value" do
      assert %{raw: raw, length: 5} = ChunkPNG.TEXT.new!("k", "v\0al")
      assert {8, 5} == :binary.match(raw, <<?k, 0, ?v, ?a, ?l>>)
    end

    test "single linefeed character" do
      assert %{raw: raw, length: 6} = ChunkPNG.TEXT.new!("k", "v\r\nal")
      assert {8, 6} == :binary.match(raw, <<?k, 0, ?v, 0x0A, ?a, ?l>>)
    end

    test "keyword with leading space" do
      assert %{raw: raw, length: 3} = ChunkPNG.TEXT.new!(" k", "v")
      assert {8, 3} == :binary.match(raw, <<?k, 0, ?v>>)
    end

    test "keyword with trailing space" do
      assert %{raw: raw, length: 3} = ChunkPNG.TEXT.new!("k ", "v")
      assert {8, 3} == :binary.match(raw, <<?k, 0, ?v>>)
    end

    test "keyword with consecutive spaces" do
      assert %{raw: raw} = ChunkPNG.TEXT.new!("k  ey", "v")
      assert :nomatch == :binary.match(raw, "  ")
      assert {8, 4} == :binary.match(raw, "k ey")
    end

    test "keyword removes restricted chars" do
      assert %{raw: raw, length: 5} = ChunkPNG.TEXT.new!(<<?k, 0x19, 0x7F, ?e, ?y>>, "v")
      assert {8, 5} == :binary.match(raw, <<?k, ?e, ?y, 0, ?v>>)
    end

    test "output with e-acute is latin-1" do
      assert %{raw: raw, length: 6} = ChunkPNG.TEXT.new!("k", "José")
      assert <<6::size(32), "tEXt", ?k, 0x00, ?J, ?o, ?s, 0xE9, _crc::size(32)>> = raw
    end
  end

  describe "Codepagex" do
    test "compiled with ISO8859-1" do
      assert Enum.member?(Codepagex.encoding_list(), "ISO8859/8859-1")
    end
  end
end
