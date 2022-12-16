defmodule ChunkPNG.TEXT do
  @moduledoc """
  tEXt Textual data

  Encode an uncompressed key-value pair using Latin-1/ISO_8859-1 character set.
  For UTF-8 see `ChunkPNG.ITXT`

  See https://www.w3.org/TR/png/#11tEXt
  """

  alias ChunkPNG.Chunk

  @chunk_type "tEXt"

  @doc """
  Create a new key-value text chunk.

  The key must be 1-79 characters.
  Raises if the input binaries contain characters outside of Latin-1 character set.
  """
  def new!(key, value) when is_binary(key) and is_binary(value) do
    latin_key = key |> String.trim() |> normalize_spaces() |> encode_latin1() |> restrict_chars()
    latin_value = value |> strip_null() |> normalize_lf() |> encode_latin1()
    if byte_size(latin_key) < 1, do: raise(ArgumentError, message: "Key too short")
    if byte_size(latin_key) > 79, do: raise(ArgumentError, message: "Key too long")
    text = latin_key <> <<0x00>> <> latin_value
    len = byte_size(text)
    crc = Chunk.crc(@chunk_type, text)
    <<raw::binary>> = <<len::size(32), @chunk_type, text::binary, crc::size(32)>>
    %Chunk{length: len, type: @chunk_type, crc: crc, raw: raw}
  end

  @doc false
  def normalize_lf(s), do: String.replace(s, ~r/\r\n/, "\n")

  @doc false
  def normalize_spaces(s), do: String.replace(s, ~r/[ ]{2,}/, " ")

  @doc false
  def strip_null(s), do: :binary.replace(s, <<0x00>>, <<>>)

  defp encode_latin1(s), do: Codepagex.from_string!(s, :iso_8859_1)

  defp restrict_chars(s) do
    for <<c <- s>>, (c >= 32 and c <= 126) or (c >= 161 and c <= 255), into: "", do: <<c>>
  end
end
