# Copyright © 2016 Jonathan Storm <the.jonathan.storm@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING.WTFPL file for more details.

defmodule NetAddr do
  @moduledoc """
  General functions for network address parsing and manipulation, with support
  for addresses of arbitrary size.
  """

  use Bitwise

  @ipv4_size 4
  @ipv6_size 16
  @mac_48_size 6

  @type t :: NetAddr.Generic.t | NetAddr.IPv4.t | NetAddr.IPv6.t | NetAddr.MAC_48.t

  defmodule Generic do
    @moduledoc """
    Defines a struct to represent network addresses of arbitrary size.
    """

    defstruct address: nil, length: nil

    @type t :: %Generic{address: binary, length: non_neg_integer}
  end

  defmodule IPv4 do
    @moduledoc """
    Defines a struct to represent IPv4 network addresses.
    """

    defstruct address: nil, length: nil

    @type t :: %IPv4{address: binary, length: non_neg_integer}
  end

  defmodule IPv6 do
    @moduledoc """
    Defines a struct to represent IPv6 network addresses.
    """

    defstruct address: nil, length: nil

    @type t :: %IPv6{address: binary, length: non_neg_integer}
  end

  defmodule MAC_48 do
    @moduledoc """
    Defines a struct to represent MAC-48 network addresses.
    """

    defstruct address: nil, length: nil

    @type t :: %MAC_48{address: binary, length: non_neg_integer}
  end

  @doc """
  Return the address length of `netaddr`.

  ## Examples
      
      iex> NetAddr.address_length NetAddr.ipv4_cidr("192.0.2.1/24")
      24
  """
  @spec address_length(NetAddr.t) :: non_neg_integer

  def address_length(netaddr) do
    netaddr.length
  end

  @doc """
  Returns a new `t:NetAddr.t/0` with the address part of `netaddr` and the given
  address length.

  ## Examples
      
      iex> NetAddr.ipv4_cidr("192.0.2.1/24") |> NetAddr.address_length(22)
      %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 22}
  """
  @spec address_length(NetAddr.t, pos_integer) :: NetAddr.t

  def address_length(netaddr, new_length) do
    %{netaddr | length: new_length}
  end

  @doc """
  Constructs a `t:NetAddr.t/0` struct given a network address binary.

  ## Examples

      iex> NetAddr.netaddr(<<1, 2, 3, 4, 5, 6>>)
      %NetAddr.MAC_48{address: <<1, 2, 3, 4, 5, 6>>, length: 48}
      
      iex> NetAddr.netaddr(<<1, 2, 3, 4, 5>>)
      %NetAddr.Generic{address: <<1, 2, 3, 4, 5>>, length: 40}
  """
  @spec netaddr(binary) :: NetAddr.t

  def netaddr(address) do
    netaddr address, byte_size(address) * 8
  end

  @doc """
  Constructs a `t:NetAddr.t/0` struct given a network address binary and an
  address length.
  """
  @spec netaddr(binary, non_neg_integer) :: NetAddr.t

  def netaddr(address, address_length) when byte_size(address) == @ipv4_size do
    %IPv4{address: address, length: address_length}
  end
  def netaddr(address, address_length) when byte_size(address) == @mac_48_size do
    %MAC_48{address: address, length: address_length}
  end
  def netaddr(address, address_length) when byte_size(address) == @ipv6_size do
    %IPv6{address: address, length: address_length}
  end
  def netaddr(address, address_length)
      when address_length in 0..(byte_size(address) * 8)
  do
    %Generic{address: address, length: address_length}
  end

  @doc """
  Explicitly constructs a `t:NetAddr.Generic.t/0` struct.

  ## Examples

      iex> NetAddr.netaddr(<<1, 2, 3, 4, 5, 6>>, 48, 6)
      %NetAddr.Generic{address: <<1, 2, 3, 4, 5, 6>>, length: 48}
      
      iex> NetAddr.netaddr(<<1, 2, 3, 4, 5>>, 48, 6)
      %NetAddr.Generic{address: <<0, 1, 2, 3, 4, 5>>, length: 48}
  """
  @spec netaddr(binary, non_neg_integer, pos_integer) :: Generic.t

  def netaddr(address, address_length, size_in_bytes)
      when address_length in 0..(size_in_bytes * 8)
  do
    embedded_address = Vector.embed address, size_in_bytes

    %Generic{address: embedded_address, length: address_length}
  end


  ############################### Conversion ###################################

  @doc """
  Converts `address_length` to an address mask binary.

  ## Examples

      iex> NetAddr.length_to_mask(30, 4)
      <<255, 255, 255, 252>>
      
      iex> NetAddr.length_to_mask(64, 16)
      <<255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0>>
      
      iex> NetAddr.length_to_mask(37, 6)
      <<255, 255, 255, 255, 248, 0>>
  """
  @spec length_to_mask(non_neg_integer, pos_integer) :: binary

  def length_to_mask(address_length, mask_length_in_bytes)
      when address_length <= (mask_length_in_bytes * 8) do

    ones = bsl(1, address_length) - 1
    mask_length_in_bits = mask_length_in_bytes * 8
    mask_number = bsl ones, mask_length_in_bits - address_length

    <<mask_number :: size(mask_length_in_bits)>>
  end

  @doc """
  Converts `address_mask` to an address length.

  ## Examples

      iex> NetAddr.mask_to_length(<<255,255,248,0>>)
      21
  """
  @spec mask_to_length(binary) :: non_neg_integer

  def mask_to_length(address_mask) do
    address_mask
      |> :binary.bin_to_list
      |> Enum.map(&Math.Binary.ones/1)
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

  @doc """
  Converts `address` to a decimal.

  ## Examples

      iex> NetAddr.aton <<192,0,2,1>>
      3221225985
      
      iex> NetAddr.aton <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>
      338288524986991696549538495105230488577
      
      iex> NetAddr.aton(<<1,2,3,4,5>>)
      4328719365
  """
  @spec aton(binary) :: non_neg_integer

  def aton(address) do
    address
      |> :binary.bin_to_list
      |> combine_bytes_into_decimal
  end

  @doc """
  Converts `decimal` to an address.

  ## Examples

      iex> NetAddr.ntoa 3221225985, 4
      <<192, 0, 2, 1>>
      
      iex> NetAddr.ntoa 338288524986991696549538495105230488577, 16
      <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>
      
      iex> NetAddr.ntoa 4328719365, 5
      <<1, 2, 3, 4, 5>>
  """
  @spec ntoa(non_neg_integer, pos_integer) :: binary

  def ntoa(decimal, size_in_bytes) do
    decimal
      |> split_decimal_into_bytes(size_in_bytes)
      |> :binary.list_to_bin
  end

  @doc """
  Converts a `t:NetAddr.t/0` to a `t:Range.t/0`.

  ## Examples

      iex> NetAddr.ipv4_cidr("198.51.100.0/24") |> NetAddr.netaddr_to_range
      3325256704..3325256959
  """
  @spec netaddr_to_range(NetAddr.t) :: Range.t

  def netaddr_to_range(netaddr) do
    a = aton first_address(netaddr).address
    b = aton  last_address(netaddr).address

    a..b
  end

  defp _range_to_netaddr(a.._ = range, size_in_bytes, struct) do
    count = Enum.count range

    len = trunc (size_in_bytes * 8) - Math.Information.log_2(count)

    address = ntoa a, size_in_bytes

    %{struct | address: address, length: len}
  end

  @doc """
  Converts `range` to a `t:NetAddr.t/0` given an address size hint.

  ## Examples

      iex> NetAddr.range_to_netaddr 3325256704..3325256959, 4
      %NetAddr.IPv4{address: <<198, 51, 100, 0>>, length: 24}
  """
  @spec range_to_netaddr(Range.t, pos_integer) :: NetAddr.t

  def range_to_netaddr(range, @ipv4_size = size_in_bytes) do
    _range_to_netaddr range, size_in_bytes, %IPv4{}
  end
  def range_to_netaddr(range, @mac_48_size = size_in_bytes) do
    _range_to_netaddr range, size_in_bytes, %MAC_48{}
  end
  def range_to_netaddr(range, @ipv6_size = size_in_bytes) do
    _range_to_netaddr range, size_in_bytes, %IPv6{}
  end
  def range_to_netaddr(range, size_in_bytes) do
    _range_to_netaddr range, size_in_bytes, %Generic{}
  end


  ############################## Pretty Printing ###############################

  @doc """
  Returns a human-readable string for the address part of `netaddr`.

  ## Examples

      iex> NetAddr.address NetAddr.ipv4_cidr("192.0.2.1/24")
      "192.0.2.1"
      
      iex> NetAddr.address NetAddr.netaddr(<<1, 2, 3, 4, 5>>)
      "0x0102030405"
  """
  @spec address(NetAddr.t) :: String.t

  def address(netaddr) do
    NetAddr.Representation.address netaddr
  end

  @doc """
  Returns a new `t:NetAddr.t/0` with the first address in `netaddr`.

  ## Examples

      iex> NetAddr.first_address NetAddr.ipv4_cidr("192.0.2.1/24")
      %NetAddr.IPv4{address: <<192, 0, 2, 0>>, length: 24}
  """
  def first_address(netaddr) do
    size  = byte_size netaddr.address
    mask  = length_to_mask netaddr.length, size
    first = apply_mask netaddr.address, mask

    %{netaddr | address: first}
  end

  @doc """
  Returns a new `t:NetAddr.t/0` with the last address in `netaddr`.

  ## Examples

      iex> NetAddr.last_address NetAddr.ipv4_cidr("192.0.2.1/24")
      %NetAddr.IPv4{address: <<192, 0, 2, 255>>, length: 24}
  """
  def last_address(netaddr) do
    size = byte_size netaddr.address
    mask = length_to_mask netaddr.length, size

    decimal  = trunc :math.pow(2, size*8) - 1
    all_ones = ntoa decimal, size

    inverse_mask = Vector.bit_xor mask, all_ones

    last = Vector.bit_or first_address(netaddr).address, inverse_mask

    %{netaddr | address: last}
  end

  @doc """
  Returns a human-readable string for the last address in `ipv4_netaddr`.

  ## Examples

      iex> NetAddr.broadcast NetAddr.ipv4_cidr("192.0.2.1/24")
      "192.0.2.255"
  """
  @spec broadcast(NetAddr.IPv4.t) :: String.t

  def broadcast(ipv4_netaddr)
  def broadcast(%IPv4{} = ipv4_netaddr) do
    ipv4_netaddr
      |> last_address
      |> address
  end

  @doc """
  Returns a human-readable string for the first address in `netaddr`.

  ## Examples

      iex> NetAddr.network NetAddr.ipv4_cidr("192.0.2.1/24")
      "192.0.2.0"
  """
  @spec network(NetAddr.t) :: String.t

  def network(netaddr) do
    netaddr
      |> first_address
      |> address
  end

  @doc """
  Returns a human-readable CIDR for the first address in `netaddr`.

  ## Examples

      iex> NetAddr.prefix %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}
      "192.0.2.0/24"
      
      iex> NetAddr.prefix %NetAddr.Generic{address: <<1, 2, 3, 4, 5>>, length: 32}
      "0x0102030400/32"
  """
  @spec prefix(NetAddr.t) :: String.t

  def prefix(netaddr) do
    netaddr
      |> first_address
      |> netaddr_to_string
  end

  @doc """
  Returns a human-readable address mask for `ipv4_netaddr`.

  ## Examples

      iex> NetAddr.subnet_mask %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}
      "255.255.255.0"
  """
  @spec subnet_mask(NetAddr.IPv4.t) :: String.t

  def subnet_mask(ipv4_netaddr)
  def subnet_mask(%IPv4{address: address, length: len}) do
    size = byte_size address
    mask = length_to_mask len, size

    address netaddr(mask, len)
  end

  @doc """
  Returns a human-readable CIDR or pseudo-CIDR for `netaddr`.

  This is like `NetAddr.prefix/1` except host bits are not set to zero. All
  `String.Chars` implementations call this function.

  ## Examples

      iex> NetAddr.netaddr_to_string %NetAddr.Generic{address: <<1, 2, 3, 4, 5>>, length: 32}
      "0x0102030405/32"
  """
  @spec netaddr_to_string(NetAddr.t) :: String.t

  def netaddr_to_string(netaddr) do
    "#{address(netaddr)}/#{address_length(netaddr)}"
  end


  ################################# Parsing ####################################

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

  @doc """
  Parses `address_string`, returning a `t:NetAddr.IPv4.t/0`.

  ## Examples

      iex> NetAddr.ipv4 "192.0.2.1"
      %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 32}
  """
  @spec ipv4(String.t) :: NetAddr.IPv4.t

  def ipv4(address_string) do
    ipv4 address_string, 32
  end

  @doc """
  Parses `address_string`, returning a `t:NetAddr.IPv4.t/0` with the given
  address length.

  ## Examples

      iex> NetAddr.ipv4 "192.0.2.1", 24
      %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}
      
      iex> NetAddr.ipv4 "192.0.2.1", "255.255.255.0"
      %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}
  """
  @spec ipv4(String.t, non_neg_integer) :: NetAddr.IPv4.t
  @spec ipv4(String.t, String.t) :: NetAddr.IPv4.t

  def ipv4(address_string, length) when is_integer length do
    address_string
      |> ipv4_string_to_bytes
      |> :binary.list_to_bin
      |> netaddr(length)
  end
  def ipv4(address_string, mask_string) when is_binary mask_string do
    netaddr_length = mask_to_length ipv4(mask_string).address

    ipv4 address_string, netaddr_length
  end

  @doc """
  Parses `cidr_string`, returning a `t:NetAddr.IPv4.t/0`.

  ## Examples

      iex> NetAddr.ipv4_cidr "192.0.2.1/24"
      %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}
  """
  @spec ipv4_cidr(String.t) :: NetAddr.IPv4.t

  def ipv4_cidr(cidr_string) do
    [address_string, length_string] = String.split cidr_string, "/"

    netaddr_length = String.to_integer length_string

    ipv4 address_string, netaddr_length
  end

  defp ipv6_string_to_byte_words(address_string) do
    {:ok, address_tuple} =
      address_string
        |> :binary.bin_to_list
        |> :inet.parse_ipv6_address

    Tuple.to_list address_tuple
  end

  @doc """
  Parses `address_string` containing an IPv6 address, returning a `t:NetAddr.IPv6.t/0`.

  ## Examples

      iex> NetAddr.ipv6 "fe80:0:c100::c401"
      %NetAddr.IPv6{address: <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>, length: 128}
  """
  @spec ipv6(String.t) :: NetAddr.IPv6.t

  def ipv6(address_string) do
    ipv6 address_string, 128
  end

  @doc """
  Parses `address_string`, returning a `t:NetAddr.IPv6.t/0` with the given
  address length.

  ## Examples

      iex> NetAddr.ipv6 "fe80:0:c100::c401", 64
      %NetAddr.IPv6{address: <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>, length: 64}
  """
  @spec ipv6(String.t, 0..128) :: NetAddr.IPv6.t

  def ipv6(address_string, address_length) do
    address_string
      |> ipv6_string_to_byte_words
      |> Enum.flat_map(&split_decimal_into_bytes(&1, 2))
      |> :binary.list_to_bin
      |> netaddr(address_length)
  end

  @doc """
  Parses `cidr_string`, returning a `t:NetAddr.IPv6.t/0`.

  ## Examples

      iex> NetAddr.ipv6_cidr "fe80:0:c100::c401/64"
      %NetAddr.IPv6{address: <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>, length: 64}
  """
  @spec ipv6_cidr(String.t) :: NetAddr.IPv6.t

  def ipv6_cidr(cidr_string) do
    [address_string, length_string] = String.split cidr_string, "/"

    netaddr_length = String.to_integer length_string

    ipv6 address_string, netaddr_length
  end

  defp _parse_mac_48(<<>>, {[], acc}) do
    # If the string is consumed and the current byte is empty,
    #   return the accumulator

    :binary.list_to_bin acc
  end
  defp _parse_mac_48(<<>>, {byte_acc, acc}) do
    # If the string is consumed and the current byte is not empty,
    #   append the current byte and return the accumulator

    byte = Math.collapse byte_acc, 16

    :binary.list_to_bin acc ++ [byte]
  end
  defp _parse_mac_48(string, {byte_acc, acc}) when length(byte_acc) == 2 do
    # When the current byte contains two characters, combine and append them

    byte = Math.collapse byte_acc, 16

    _parse_mac_48 string, {[], acc ++ [byte]}
  end
  defp _parse_mac_48(<<head, tail::binary>>, {[], acc})
      when head in ':-. ' do
    # When a new delimiter is found and the current byte is empty, consume tail

    _parse_mac_48 tail, {[], acc}
  end
  defp _parse_mac_48(<<head, tail::binary>>, {byte_acc, acc})
      when head in ':-. ' do
    # When a new delimiter is found, append the current byte to the accumulator

    byte = Math.collapse byte_acc, 16

    _parse_mac_48 tail, {[], acc ++ [byte]}
  end
  defp _parse_mac_48(<<head, tail::binary>>, {byte_acc, acc})
      when head in ?0..?9 or head in ?a..?f or head in ?A..?F do
    # Convert hexadecimal character to decimal and append it to the current byte

    {nibble, _} = Integer.parse <<head>>, 16

    _parse_mac_48 tail, {byte_acc ++ [nibble], acc}
  end
  defp _parse_mac_48(<<_, tail::binary>>, {byte_acc, acc}) do
    # When no other clause matches, blindly consume tail

    _parse_mac_48 tail, {byte_acc, acc}
  end

  defp parse_mac_48(string) do
    _parse_mac_48 string, {[], []}
  end

  @doc """
  Parses `mac_string`, returning a `t:NetAddr.MAC_48.t/0`.

  For manifest reasons, the corresponding parser may be robust to the point of
  returning incorrect results. *Caveat emptor*.

  ## Examples

      iex> NetAddr.mac_48 "\\"c0fF:33-C0.Ff   33\\""
      %NetAddr.MAC_48{address: <<0xc0, 0xff, 0x33, 0xc0, 0xff, 0x33>>, length: 48}
  """
  @spec mac_48(binary) :: NetAddr.MAC_48.t

  def mac_48(mac_string) do
    mac_string
      |> String.strip
      |> parse_mac_48
      |> netaddr(48)
  end


  ################################ Utilities ###################################

  @doc """
  Bitwise ANDs two address binaries, returning the result.

  ## Examples

      iex> NetAddr.apply_mask <<192, 0, 2, 1>>, <<255, 255, 255, 0>>
      <<192, 0, 2, 0>>
  """
  @spec apply_mask(binary, binary) :: binary

  def apply_mask(address, mask) when is_binary(address) and is_binary(mask) do
    Vector.bit_and address, mask
  end

  @doc """
  Returns `true` if `netaddr2` is a subset of `netaddr1`, up to equality. Otherwise,
  returns `false`.

  ## Examples

      iex> NetAddr.ipv4_cidr("192.0.2.0/24") |> NetAddr.contains?(NetAddr.ipv4_cidr("192.0.2.0/25"))
      true
      
      iex> NetAddr.ipv4_cidr("192.0.2.0/24") |> NetAddr.contains?(NetAddr.ipv4_cidr("192.0.2.0/24"))
      true
      
      iex> NetAddr.ipv4_cidr("192.0.2.0/25") |> NetAddr.contains?(NetAddr.ipv4_cidr("192.0.2.0/24"))
      false
      
      iex> NetAddr.ipv4_cidr("192.0.2.0/25") |> NetAddr.contains?(NetAddr.ipv4_cidr("192.0.2.128/25"))
      false
  """
  @spec contains?(NetAddr.t, NetAddr.t) :: boolean

  def contains?(netaddr1, netaddr2)
  def contains?(%{length: len1} = netaddr1, %{length: len2} = netaddr2)
      when len1 <= len2
  do
    address_size = byte_size netaddr1.address

    mask = length_to_mask netaddr1.length, address_size

    masked_address = apply_mask netaddr2.address, mask

    masked_address == netaddr1.address
  end
  def contains?(_, _) do
    false
  end
end


defprotocol NetAddr.Representation do
  @spec address(NetAddr.t, list) :: String.t
  def address(netaddr, opts \\ [])
end


defimpl NetAddr.Representation, for: NetAddr.IPv4 do
  def address(netaddr, _opts) do
    netaddr.address
      |> :binary.bin_to_list
      |> Enum.join(".")
  end
end


defimpl NetAddr.Representation, for: NetAddr.IPv6 do
  defp drop_leading_zeros(string) when is_binary string do
    string
      |> String.lstrip(?0)
      |> String.rjust(1, ?0)
  end

  defp compress_ipv6_string(string) do
    string
      |> String.reverse
      |> String.replace(~r/:(0+:)+/, "::", global: false)
      |> String.reverse
  end

  def address(netaddr, _opts) do
    netaddr.address
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
      |> compress_ipv6_string
  end
end


defimpl NetAddr.Representation, for: NetAddr.MAC_48 do
  def address(netaddr, opts) do
    delimiter = Keyword.get opts, :delimiter, ":"

    netaddr.address
      |> :binary.bin_to_list
      |> Enum.map(&Base.encode16(<<&1>>))
      |> Enum.join(delimiter)
  end
end


defimpl NetAddr.Representation, for: NetAddr.Generic do
  def address(netaddr, _opts) do
    hex_with_len =
      netaddr.address
        |> :binary.bin_to_list
        |> Enum.map(&Base.encode16(<<&1>>))
        |> Enum.join("")

    "0x#{hex_with_len}"
  end
end


defimpl String.Chars, for: NetAddr.IPv4 do
  import Kernel, except: [to_string: 1]

  def to_string(netaddr) do
    NetAddr.netaddr_to_string netaddr
  end
end


defimpl String.Chars, for: NetAddr.IPv6 do
  import Kernel, except: [to_string: 1]

  def to_string(netaddr) do
    NetAddr.netaddr_to_string netaddr
  end
end


defimpl String.Chars, for: NetAddr.MAC_48 do
  import Kernel, except: [to_string: 1]

  def to_string(netaddr) do
    NetAddr.netaddr_to_string netaddr
  end
end


defimpl String.Chars, for: NetAddr.Generic do
  import Kernel, except: [to_string: 1]

  def to_string(netaddr) do
    NetAddr.netaddr_to_string netaddr
  end
end
