defmodule ChunkPNG.Chunk do
  @moduledoc "Data structure of a PNG chunk"

  @type t :: binary | %{required(:raw) => binary}

  defstruct length: 0, type: nil, crc: nil, raw: nil

  @doc false
  def crc(type, data) when is_binary(type) and is_binary(data) do
    :erlang.crc32(<<type::binary-size(4), data::binary>>)
  end
end
