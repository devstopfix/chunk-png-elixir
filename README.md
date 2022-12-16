# ChunkPNG

Library for manipulating metadata in PNG files.

## About

PNG files consist of a magic number, a mandatory header chunk, then a list of
optional chunks. This library splits the file into a list of chunks with a
cursor and allows you to insert and remove chunks.

A standard PNG may consist of:

1. magic number (8 bytes)
2. `IHDR` - mandatory first chunk of a PNG datastream
3. `PLTE` - pallete for indexed PNG images
4. `IDAT` - image data chunk(s)
5. `IEND` - image trailer, the last in a PNG datastream

Consider the use case of inserting copyright metadata. After parsing your image
you receive a list of chunks in the form of a list-zipper which is a tuple of
the list of chunks up until IDHR, then the focus (probably PLTE), then the
remaining list of chunks after the focus. You may immediately insert your
new chunks to the left of the focus and after the IHDR, or navigate to the
end and append new chunks there.

There are three forms of textual chunks:

* `tEXt` - simple key-value using the Latin-1 character set
* `iTXt` - simple key-value using UTF-8 encoding with optional value compression
* `zTXt` - equivalent to `tEXt` but using deflate compression for large text blocks

When finished the list of chunks can be written out to a file or a buffer.

## Installation

From hex:

```elixir
{:chunk_png, "~> 1.0"}
```

This library relies on [codepagex] for [Latin-1/ISO 8859-1 encoding][latin1] and for 
faster compilation we recommend adding this configuration to your application:

```elixir
config :codepagex, :encodings, [:iso_8859_1]
```

[codepagex]: https://github.com/tallakt/codepagex#encoding-selection
[latin1]: https://en.wikipedia.org/wiki/ISO/IEC_8859-1