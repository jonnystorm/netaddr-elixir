defmodule NetAddr do
  use Bitwise

  @ipv4_size 4
  @ipv6_size 16
  @mac_48_size 6

  @type t :: NetAddr.Generic.t | NetAddr.IPv4.t | NetAddr.IPv6.t | NetAddr.MAC_48.t

  defmodule Generic do
    defstruct address: nil, length: nil

    @type t :: %Generic{address: binary, length: non_neg_integer}
  end

  defmodule IPv4 do
    defstruct address: nil, length: nil

    @type t :: %IPv4{address: binary, length: non_neg_integer}
  end

  defmodule IPv6 do
    defstruct address: nil, length: nil

    @type t :: %IPv6{address: binary, length: non_neg_integer}
  end

  defmodule MAC_48 do
    defstruct address: nil, length: nil

    @type t :: %MAC_48{address: binary, length: non_neg_integer}
  end

  @spec address_length(Generic.t) :: non_neg_integer

  def address_length(netaddr) do
    netaddr.length
  end

  @spec netaddr(binary) :: NetAddr.t

  def netaddr(address) do
    netaddr address, byte_size(address)
  end

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
      when address_length in 0..(byte_size(address) * 8) do

    %Generic{address: address, length: address_length}
  end

  @spec netaddr(binary, non_neg_integer, pos_integer) :: Generic.t

  def netaddr(address, address_length, size_in_bytes)
      when address_length in 0..(size_in_bytes * 8) do

    embedded_address = Vector.embed address, size_in_bytes

    %Generic{address: embedded_address, length: address_length}
  end

  ############################### Conversion ###################################

  @spec length_to_mask(non_neg_integer, pos_integer) :: binary

  def length_to_mask(netaddr_length, mask_length_in_bytes)
      when netaddr_length <= (mask_length_in_bytes * 8) do

    ones = bsl(1, netaddr_length) - 1
    mask_length_in_bits = mask_length_in_bytes * 8
    mask_number = bsl ones, mask_length_in_bits - netaddr_length

    <<mask_number :: size(mask_length_in_bits)>>
  end

  @spec mask_to_length(binary) :: non_neg_integer

  def mask_to_length(mask) do
    mask
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

  @spec aton(binary) :: non_neg_integer

  def aton(address) do
    address
      |> :binary.bin_to_list
      |> combine_bytes_into_decimal
  end

  @spec ntoa(non_neg_integer, pos_integer) :: binary

  def ntoa(decimal, size_in_bytes) do
    decimal
      |> split_decimal_into_bytes(size_in_bytes)
      |> :binary.list_to_bin
  end

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

  @spec address(NetAddr.t) :: String.t

  def address(netaddr) do
    NetAddr.Representation.address netaddr
  end

  def first_address(netaddr) do
    size = byte_size netaddr.address
    mask = length_to_mask netaddr.length, size

    %{netaddr | address: apply_mask(netaddr, mask)}
  end

  def last_address(netaddr) do
    size = byte_size netaddr.address
    mask = length_to_mask netaddr.length, size

    decimal  = trunc :math.pow(2, size*8) - 1
    all_ones = ntoa decimal, size

    inverse_mask = Vector.bit_xor mask, all_ones

    last = Vector.bit_or first_address(netaddr).address, inverse_mask

    %{netaddr | address: last}
  end

  @spec broadcast(NetAddr.t) :: String.t

  def broadcast(%IPv4{} = netaddr) do
    netaddr
      |> last_address
      |> address
  end

  @spec network(NetAddr.t) :: String.t

  def network(netaddr) do
    netaddr
      |> first_address
      |> address
  end

  @spec prefix(NetAddr.t) :: String.t

  def prefix(netaddr) do
    netaddr_to_string netaddr
  end

  @spec subnet_mask(NetAddr.t) :: String.t

  def subnet_mask(%{address: address, length: len}) do
    size = byte_size address
    mask = length_to_mask len, size

    address netaddr(mask, len)
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

  @spec ipv4(String.t) :: NetAddr.IPv4.t

  def ipv4(address_string) do
    ipv4 address_string, 32
  end

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

  @spec ipv6(String.t) :: NetAddr.IPv6.t

  def ipv6(address_string) do
    ipv6 address_string, 128
  end

  @spec ipv6(String.t, 0..128) :: NetAddr.IPv6.t

  def ipv6(address_string, address_length) do
    address_string
      |> ipv6_string_to_byte_words
      |> Enum.flat_map(&split_decimal_into_bytes(&1, 2))
      |> :binary.list_to_bin
      |> netaddr(address_length)
  end

  @spec ipv6_cidr(String.t) :: NetAddr.IPv6.t

  def ipv6_cidr(netaddr_string) do
    [address_string, length_string] = String.split netaddr_string, "/"

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

  @spec mac_48(binary) :: NetAddr.MAC_48.t

  def mac_48(string) do
    string
      |> String.strip
      |> parse_mac_48
      |> netaddr(48)
  end


  ################################ Utilities ###################################

  @spec apply_mask(NetAddr.t, binary) :: binary

  def apply_mask(netaddr, mask) when is_binary mask do
    Vector.bit_and netaddr.address, mask
  end

  @spec contains?(NetAddr.t, NetAddr.t) :: boolean

  def contains?(netaddr1, netaddr2) do
    address_size = byte_size netaddr1.address

    masked_network =
      apply_mask netaddr2, length_to_mask(netaddr1.length, address_size)

    masked_network == netaddr1.address
  end

  @spec netaddr_to_string(NetAddr.t) :: String.t

  def netaddr_to_string(netaddr) do
    "#{address(netaddr)}/#{address_length(netaddr)}"
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
