defmodule NetAddr do
  use Bitwise

  defmodule Prefix do
    defstruct address: nil, length: nil

    @type t :: %Prefix{address: Bitstring.t, length: non_neg_integer}

    @spec address(Prefix.t) :: Bitstring.t
    def address(prefix) do
      prefix.address
    end

    @spec length(Prefix.t) :: non_neg_integer
    def length(prefix) do
      prefix.length
    end

    @spec length(Prefix.t, non_neg_integer) :: Prefix.t
    def length(prefix, value) when is_integer(value) do
      new_prefix_length =
        value
          |> Math.mod(bit_size(prefix.address) + 1)

      mask =
        new_prefix_length
          |> NetAddr.prefix_length_to_mask(byte_size prefix.address)

      address = Vector.bit_and prefix.address, mask

      %Prefix{prefix|address: address, length: new_prefix_length}
    end
  end

  @spec prefix(Bitstring.t, non_neg_integer, pos_integer) :: NetAddr.Prefix.t
  def prefix(address, prefix_length, size_in_bytes)
      when byte_size(address) == size_in_bytes
      and prefix_length in 0..(size_in_bytes * 8) do

    %NetAddr.Prefix{address: address}
      |> NetAddr.Prefix.length(prefix_length)
  end
  def prefix(address, prefix_length, size_in_bytes)
      when prefix_length in 0..(size_in_bytes * 8) do

    address
      |> Vector.embed(size_in_bytes)
      |> prefix(prefix_length, size_in_bytes)
  end


  ## Conversion ##

  @spec prefix_length_to_mask(non_neg_integer, pos_integer) :: Bitstring.t
  def prefix_length_to_mask(prefix_length, mask_length_in_bytes)
      when prefix_length <= (mask_length_in_bytes * 8) do

    ones = bsl(1, prefix_length) - 1
    mask_length_in_bits = mask_length_in_bytes * 8
    mask_number = bsl(ones, mask_length_in_bits - prefix_length)

    <<mask_number :: size(mask_length_in_bits)>>
  end

  @spec mask_to_prefix_length(Bitstring.t) :: non_neg_integer
  def mask_to_prefix_length(mask) do
    mask
      |> :binary.bin_to_list
      |> Enum.map(fn byte -> Math.Binary.ones byte end)
      |> Enum.sum
  end

  defp combine_bytes_into_decimal(bytes) do
    Math.collapse bytes, 256
  end

  defp split_decimal_into_bytes(decimal, byte_count) do
    decimal
      |> Math.expand(256)
      |> Vector.embed(byte_count)
  end

  @spec aton(Bitstring.t) :: non_neg_integer
  def aton(address) do
    address
      |> :binary.bin_to_list
      |> combine_bytes_into_decimal
  end

  @spec ntoa(non_neg_integer, pos_integer) :: Bitstring.t
  def ntoa(decimal, size) do
    byte_count = trunc Float.ceil(size / 8)

    decimal
      |> split_decimal_into_bytes(byte_count)
      |> :binary.list_to_bin
  end

  @spec ipv4_ntoa(non_neg_integer) :: Bitstring.t
  def ipv4_ntoa(decimal) do
    ntoa decimal, 32
  end

  @spec ipv6_ntoa(non_neg_integer) :: Bitstring.t
  def ipv6_ntoa(decimal) do
    ntoa decimal, 128
  end


  ## Pretty-printing ##

  @spec prefix_to_ipv4(NetAddr.Prefix.t) :: String.t
  def prefix_to_ipv4(prefix) do
    prefix
      |> NetAddr.Prefix.address
      |> :binary.bin_to_list
      |> Enum.join(".")
  end

  @spec prefix_to_ipv4_cidr(NetAddr.Prefix.t) :: String.t
  def prefix_to_ipv4_cidr(prefix) do
    address = prefix_to_ipv4 prefix
    prefix_length = NetAddr.Prefix.length prefix

    "#{address}/#{prefix_length}"
  end

  defp drop_leading_zeros(string) when is_binary string do
    string
      |> String.lstrip(?0)
      |> String.rjust(1, ?0)
  end

  @spec prefix_to_ipv6_prefix_string(NetAddr.Prefix.t) :: String.t
  def prefix_to_ipv6_prefix_string(prefix) do
    length = NetAddr.Prefix.length(prefix)

    string = prefix
      |> NetAddr.Prefix.address
      |> :binary.bin_to_list
      |> Enum.chunk(2)
      |> Enum.map(fn word ->
        word
          |> :binary.list_to_bin
          |> Base.encode16
          |> String.downcase
          |> drop_leading_zeros
      end)
      |> Enum.join(":")

    String.downcase "#{string}/#{length}"
  end

  @spec compress_ipv6_string(String.t) :: String.t
  def compress_ipv6_string(string) do
    string
      |> String.reverse
      |> String.replace(~r/:(0+:)+/, "::", global: false)
      |> String.reverse
  end

  def prefix_to_mac(prefix, delimiter \\ ":") do
    prefix
      |> NetAddr.Prefix.address
      |> :binary.bin_to_list
      |> Enum.map(&Base.encode16(<<&1>>))
      |> Enum.join(delimiter)
  end


  ## Parsing ##

  defp ipv4_string_to_bytes(address_string) do
    try do
      {:ok, address_tuple} =
        address_string
          |> :binary.bin_to_list
          |> :inet.parse_ipv4_address

      Tuple.to_list address_tuple

    rescue
      _ in MatchError ->
        raise ArgumentError, message: "Cannot parse as IPv4: '#{address_string}'"
    end
  end

  @spec ipv4(String.t) :: NetAddr.Prefix.t
  def ipv4(address_string) do
    ipv4 address_string, 32
  end

  @spec ipv4(String.t, non_neg_integer) :: NetAddr.Prefix.t
  @spec ipv4(String.t, String.t) :: NetAddr.Prefix.t
  def ipv4(address_string, length) when is_integer length do
    address_string
      |> ipv4_string_to_bytes
      |> :binary.list_to_bin
      |> prefix(length, 4)
  end
  def ipv4(address_string, mask_string) when is_binary mask_string do
    length =
      mask_string
        |> ipv4
        |> NetAddr.Prefix.address
        |> mask_to_prefix_length

    ipv4 address_string, length
  end

  @spec ipv4_cidr(String.t) :: NetAddr.Prefix.t
  def ipv4_cidr(cidr_string) do
    [address_string, length_string] = String.split cidr_string, "/"
    length = String.to_integer length_string

    ipv4 address_string, length
  end

  defp ipv6_string_to_byte_words(address_string) do
    {:ok, address_tuple} =
      address_string
        |> :binary.bin_to_list
        |> :inet.parse_ipv6_address

    Tuple.to_list address_tuple
  end

  @spec ipv6(String.t) :: NetAddr.Prefix.t
  def ipv6(address_string) do
    ipv6 address_string, 128
  end

  @spec ipv6(String.t) :: NetAddr.Prefix.t
  def ipv6(address_string, length) do
    address_string
      |> ipv6_string_to_byte_words
      |> Enum.flat_map(fn word -> split_decimal_into_bytes word, 2 end)
      |> :binary.list_to_bin
      |> prefix(length, 16)
  end

  @spec ipv6_prefix(String.t) :: NetAddr.Prefix.t
  def ipv6_prefix(prefix_string) do
    [address_string, length_string] = String.split prefix_string, "/"
    length = String.to_integer length_string

    ipv6 address_string, length
  end

  defp hexadecimal_character_to_decimal(hex_character) do
    %{
      ?0 => 0,
      ?1 => 1,
      ?2 => 2,
      ?3 => 3,
      ?4 => 4,
      ?5 => 5,
      ?6 => 6,
      ?7 => 7,
      ?8 => 8,
      ?9 => 9,
      ?a => 10, ?A => 10,
      ?b => 11, ?B => 11,
      ?c => 12, ?C => 12,
      ?d => 13, ?D => 13,
      ?e => 14, ?E => 14,
      ?f => 15, ?F => 15
    }[hex_character]
  end

  defp _parse_mac_address(<<>>, {[], acc}) do
    # If the string is consumed and the current byte empty, return the accumulator

    :binary.list_to_bin acc
  end
  defp _parse_mac_address(<<>>, {byte_acc, acc}) do
    # If the string is consumed and the current byte is not empty,
    #   append the current byte and return the accumulator

    byte = Math.collapse byte_acc, 16

    :binary.list_to_bin acc ++ [byte]
  end
  defp _parse_mac_address(string, {byte_acc, acc}) when length(byte_acc) == 2 do
    # When the current byte contains two characters, combine and append them

    byte = Math.collapse byte_acc, 16

    _parse_mac_address string, {[], acc ++ [byte]}
  end
  defp _parse_mac_address(<<head, tail::binary>>, {[], acc})
      when head in ':-. ' do
    # When a new delimiter is found and the current byte is empty, consume tail

    _parse_mac_address tail, {[], acc}
  end
  defp _parse_mac_address(<<head, tail::binary>>, {byte_acc, acc})
      when head in ':-. ' do
    # When a new delimiter is found, append the current byte to the accumulator

    byte = Math.collapse byte_acc, 16

    _parse_mac_address tail, {[], acc ++ [byte]}
  end
  defp _parse_mac_address(<<head, tail::binary>>, {byte_acc, acc})
      when head in ?0..?9 or head in ?a..?f or head in ?A..?F do
    # Convert hexadecimal character to decimal and append it to the current byte

    nibble = hexadecimal_character_to_decimal head

    _parse_mac_address tail, {byte_acc ++ [nibble], acc}
  end
  defp _parse_mac_address(<<_, tail::binary>>, {byte_acc, acc}) do
    # When no other clause matches, blindly consume tail

    _parse_mac_address tail, {byte_acc, acc}
  end

  defp parse_mac_address(string) do
    _parse_mac_address string, {[], []}
  end

  def mac(string) do
    string
      |> String.strip
      |> parse_mac_address
      |> NetAddr.prefix(48, 6)
  end


  ## Utilities ##

  def apply_mask(mask, prefix) do
    prefix
      |> NetAddr.Prefix.address
      |> Vector.bit_and(mask)
  end

  def contains?(prefix1, prefix2) do
    address_size =
      prefix1
        |> NetAddr.Prefix.address
        |> byte_size

    masked_network =
      prefix1
        |> NetAddr.Prefix.length
        |> prefix_length_to_mask(address_size)
        |> apply_mask(prefix2)

    masked_network == NetAddr.Prefix.address(prefix1)
  end
end
