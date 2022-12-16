defmodule ChunkPNG.ITXT do
  @moduledoc """
  iTXt International textual data

  Encode and uncompressed key-value pair using UTF-8.

  See https://www.w3.org/TR/png/#11iTXt
  """

  import ChunkPNG.TEXT, only: [normalize_lf: 1, normalize_spaces: 1, strip_null: 1]
  alias ChunkPNG.Chunk

  @chunk_type "iTXt"
  @compression_method 0x00
  @language_tag ~r/^[a-zA-Z]{1,8}(?:-[a-zA-Z0-9]{1,8})*$/
  @uncompressed 0x00

  @doc """
  Create a new key-value text chunk.

  The key must be 1-79 characters.
  """
  def new(key, value, language \\ "")
      when is_binary(key) and is_binary(value) and is_binary(language) do
    key = key |> String.trim() |> normalize_spaces() |> strip_null()
    value = value |> normalize_lf() |> strip_null()
    if byte_size(key) < 1, do: raise(ArgumentError, message: "Key too short")
    if byte_size(key) > 79, do: raise(ArgumentError, message: "Key too long")

    if language != "" and !String.match?(language, @language_tag),
      do: raise(ArgumentError, message: "Invalid language tag")

    text =
      key <> <<0x00, @uncompressed, @compression_method, language::binary, 0x00, 0x00>> <> value

    len = byte_size(text)
    crc = Chunk.crc(@chunk_type, text)
    <<raw::binary>> = <<len::size(32), @chunk_type, text::binary, crc::size(32)>>
    %Chunk{length: len, type: @chunk_type, crc: crc, raw: raw}
  end
end
