defmodule NetAddr do
  use Bitwise

  defmodule Prefix do
    defstruct network: nil, length: nil

    @type t :: %Prefix{network: bitstring, length: pos_integer}

    def network(prefix) do
      prefix.network
    end

    def length(prefix) do
      prefix.length
    end
  end

  def prefix(address, length, size)
      when bit_size(address) == size and length in 0..size do
    mask = length_to_mask(length, size)
    network = Vector.bit_and(address, mask)

    %NetAddr.Prefix{network: network, length: length}
  end

  def combine_bytes_into_number(bytes) do
    bytes
    |> Enum.reverse
    |> Enum.with_index
    |> Enum.reduce(0, fn({byte, index}, acc) ->
      acc + bsl(byte, index * 8)
    end)
  end

  def prefix_to_ipv6_string(prefix) do
    prefix
    |> NetAddr.Prefix.network
    |> :binary.bin_to_list
    |> Enum.chunk(2)
    |> Enum.map(fn word -> combine_bytes_into_number(word) end)
    |> Enum.join(":")
  end

  def length_to_mask(prefix_length, mask_length)
      when prefix_length <= mask_length do
    ones = bsl(1, prefix_length) - 1
    mask_number = bsl(ones, mask_length - prefix_length)

    <<mask_number :: size(mask_length)>>
  end

  def mask_to_length(mask) do
    mask
    |> :binary.bin_to_list
    |> Enum.map(fn byte -> Math.Binary.ones(byte) end)
    |> Enum.sum
  end

  defp ipv4_string_to_tuple(address_string) do
    {:ok, address_tuple} = address_string
    |> :binary.bin_to_list
    |> :inet.parse_ipv4_address

    address_tuple
  end

  def ipv4(address_string) do
    ipv4(address_string, 32)
  end

  def ipv4(address_string, length) when is_integer(length) do
    address_string
    |> ipv4_string_to_tuple
    |> Tuple.to_list
    |> :binary.list_to_bin
    |> prefix(length, 32)
  end

  def ipv4_cidr(cidr_string) do
    [address_string, length_string] = String.split(cidr_string, "/")
    length = String.to_integer length_string

    ipv4(address_string, length)
  end

  defp ipv6_string_to_tuple(address_string) do
    {:ok, address_tuple} = address_string
    |> :binary.bin_to_list
    |> :inet.parse_ipv6_address

    address_tuple
  end

  def split_number_into_bytes(number, byte_count) do
    bits = byte_count * 8
    :binary.bin_to_list(<<number :: size(bits)>>)
  end

  def ipv6(address_string) do
    ipv6(address_string, 128)
  end

  def ipv6(address_string, length) do
    address_string
    |> ipv6_string_to_tuple
    |> Tuple.to_list
    |> Enum.flat_map(fn word -> split_number_into_bytes(word, 2) end)
    |> :binary.list_to_bin
    |> prefix(length, 128)
  end

  def ipv6_prefix(prefix_string) do
    [address_string, length_string] = String.split(prefix_string, "/")
    length = String.to_integer length_string

    ipv6(address_string, length)
  end
end
