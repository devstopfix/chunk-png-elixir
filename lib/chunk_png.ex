defmodule ChunkPNG do
  @moduledoc """
  Library for manipulating metadata in PNG files.

  PNG files consist of a magic number, a mandatory header chunk, then a list of
  optional chunks. This library splits the file into a list of chunks with a
  cursor and allows you to insert and remove chunks.

  A standard PNG may consist of:

  1. magic number (8 bytes)
  2. IHDR - mandatory first chunk of a PNG datastream
  3. PLTE - pallete for indexed PNG images `<--`
  4. IDAT - image data chunk(s)
  5. IEND - image trailer, the last in a PNG datastream

  Consider the use case of inserting copyright metadata. After parsing your image
  you receive a list of chunks in the form of a list-zipper which is a tuple of
  the list of chunks up until IDHR, then the focus (probably PLTE), then the
  remaining list of chunks after the focus. You may immediately insert your
  new chunks to the left of the focus and after the IHDR, or navigate to the
  end and append new chunks there.

  There are three forms of textual chunks:

  * `tEXt` - simple key-value using the Latin-1 character set (see `ChunkPNG.TEXT`)
  * `iTXt` - simple key-value using UTF-8 encoding with optional value compression (see `ChunkPNG.ITXT`)
  * `zTXt` - equivalent to `tEXt` but using deflate compression for large text blocks

  When finished the list of chunks can be written out to a file or a buffer.
  """

  alias ChunkPNG.Chunk

  @type zipper :: {list(Chunk.t()), Chunk.t(), list(Chunk.t())}

  @doc "Parse a PNG file into a zipper of a list of chunks"
  def parse_file!(path) do
    path
    |> File.read!()
    |> parse_buffer()
  end

  @doc "Parse a PNG from in-memory buffer"
  @spec parse_buffer(binary) :: {:ok, zipper} | {:error, any}
  def parse_buffer(data) when is_binary(data) do
    case data do
      <<0x89, ?P, ?N, ?G, 0x0D, 0x0A, 0x1A, 0x0A, chunks::binary>> ->
        <<header::binary-size(8), _data::binary>> = data
        [ihdr, chunk | chunks] = parse_chunks(chunks)
        {:ok, {[ihdr, header], chunk, chunks}}

      _ ->
        {:error, :not_png}
    end
  end

  @doc "Insert a chunk to the left of the focus"
  def insert_left({left, focus, right}, chunk), do: {[chunk | left], focus, right}

  @doc "Write a chunk zipper as a binary PNG datastream"
  def write_buffer({left, focus, right}) do
    chunks = Enum.reverse(left) ++ [focus | right]

    raws =
      for chunk <- chunks do
        case chunk do
          %{raw: raw} when is_binary(raw) -> raw
          raw when is_binary(raw) -> raw
        end
      end

    IO.iodata_to_binary(raws)
  end

  @doc "Write a chunk zipper to a PNG file"
  def write_file({left, focus, right}, path) do
    File.open(path, [:write], fn f ->
      chunks = Enum.reverse(left) ++ [focus | right]
      for chunk <- chunks, do: write(f, chunk)
    end)

    :ok
  end

  defp parse_chunks(data) do
    case data do
      <<>> ->
        []

      <<length::size(32), type::binary-size(4), _::binary-size(length), crc::size(32),
        chunks::binary>> ->
        raw = :binary.part(data, {0, length + 12})
        chunk = %Chunk{length: length, type: type, crc: crc, raw: raw}
        [chunk | parse_chunks(chunks)]
    end
  end

  defp write(f, %{raw: raw}) when is_binary(raw), do: IO.binwrite(f, raw)
  defp write(f, raw) when is_binary(raw), do: IO.binwrite(f, raw)
end
