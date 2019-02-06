# This Source Code Form is subject to the terms of the
# Mozilla Public License, v. 2.0. If a copy of the MPL was
# not distributed with this file, You can obtain one at
# http://mozilla.org/MPL/2.0/.

defmodule NetAddr do
  @moduledoc """
  General functions for network address parsing and
  manipulation, with support for addresses of arbitrary
  size.
  """

  alias NetAddr.{
    IPv4,
    IPv6,
    MAC_48,
    Generic,
    Utility,
  }

  use Bitwise

  defmacro __using__(_opts) do
    quote do
      import NetAddr, only: [sigil_p: 2]
    end
  end

  @doc """
  Succinctly describe IP NetAddrs at compile time.

  ## Examples

      iex> use NetAddr
      iex> ~p"192.0.2.1/24"
      %NetAddr.IPv4{address: <<192,0,2,1>>, length: 24}

      iex> use NetAddr
      iex> ~p"2001:db8::1"
      %NetAddr.IPv6{
        address: <<0x2001::16,0xdb8::16,0::5*16,1::16>>,
        length: 128,
      }

      iex> use NetAddr
      iex> ~p(192.0.2.1/24 2001:db8::1)
      [ %NetAddr.IPv4{address: <<192,0,2,1>>, length: 24},
        %NetAddr.IPv6{
          address: <<0x2001::16,0xdb8::16,0::5*16,1::16>>,
          length: 128,
        },
      ]
  """
  defmacro sigil_p(term, modifiers)

  defmacro sigil_p({:<<>>, _meta, [string]}, _options)
      when is_binary(string)
  do
    list =
      string
      |> String.split
      |> Enum.map(fn str ->
        {:ok, netaddr} =
          str
          |> :elixir_interpolation.unescape_chars
          |> NetAddr.ip_2
          |> Macro.escape

        netaddr
      end)

    with [netaddr] <- list, do: netaddr
  end

  defmacro sigil_p({:<<>>, meta, pieces}, _options) do
    unescaped =
      :elixir_interpolation.unescape_tokens(pieces)

    binary = {:<<>>, meta, unescaped}

    quote do
      list =
        unquote(binary)
        |> String.split
        |> Enum.map(fn str ->
          {:ok, netaddr} = NetAddr.ip_2(unquote(binary))

          netaddr
        end)

      with [netaddr] <- list, do: netaddr
    end
  end

  @ipv4_size 4
  @ipv6_size 16
  @mac_48_size 6

  @type t
    :: Generic.t
     | IPv4.t
     | IPv6.t
     | MAC_48.t

  defmodule Generic do
    @moduledoc """
    Defines a struct to represent network addresses of
    arbitrary size.
    """

    defstruct [:address, :length]

    @type t
      :: %__MODULE__{
           address: binary,
           length: non_neg_integer,
         }
  end

  defmodule IPv4 do
    @moduledoc """
    Defines a struct to represent IPv4 network addresses.
    """

    defstruct [:address, :length]

    @type t
      :: %__MODULE__{address: <<_::32>>, length: 0..32}
  end

  defmodule IPv6 do
    @moduledoc """
    Defines a struct to represent IPv6 network addresses.
    """

    defstruct [:address, :length]

    @type t
      :: %__MODULE__{address: <<_::128>>, length: 0..128}
  end

  defmodule MAC_48 do
    @moduledoc """
    Defines a struct to represent MAC-48 network addresses.
    """

    defstruct [:address, :length]

    @type t
      :: %__MODULE__{address: <<_::48>>, length: 0..48}
  end

  defp wrap_result(result) do
    case result do
      {:error, _} = error ->
        error

      value ->
        {:ok, value}
    end
  end

  @doc """
  Return the address length of `netaddr`.

  ## Examples

      iex> NetAddr.address_length NetAddr.ip("192.0.2.1/24")
      24
  """
  @spec address_length(NetAddr.t)
    :: non_neg_integer
  def address_length(netaddr),
    do: netaddr.length

  @doc """
  Returns a new `t:NetAddr.t/0` with the address part of
  `netaddr` and the given address length.

  ## Examples

      iex> NetAddr.ip("192.0.2.1/24")
      ...>   |> NetAddr.address_length(22)
      %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 22}
  """
  @spec address_length(NetAddr.t, pos_integer)
    :: NetAddr.t
  def address_length(netaddr, new_length),
    do: %{netaddr | length: new_length}

  @doc """
  Returns size of `netaddr` in bytes.

  ## Examples

      iex> NetAddr.address_size NetAddr.ip("192.0.2.1")
      4

      iex> NetAddr.address_size NetAddr.ip("::")
      16

      iex> NetAddr.address_size NetAddr.mac_48("c0:ff:33:c0:ff:33")
      6

      iex> NetAddr.address_size NetAddr.netaddr(<<1, 2, 3, 4, 5>>)
      5
  """
  @spec address_size(NetAddr.t)
    :: pos_integer
  def address_size(netaddr),
    do: byte_size netaddr.address

  @doc """
  Constructs a `t:NetAddr.t/0` struct given a network
  address binary.

  ## Examples

      iex> NetAddr.netaddr <<1, 2, 3, 4, 5, 6>>
      %NetAddr.MAC_48{address: <<1, 2, 3, 4, 5, 6>>, length: 48}

      iex> NetAddr.netaddr <<1, 2, 3, 4, 5>>
      %NetAddr.Generic{address: <<1, 2, 3, 4, 5>>, length: 40}
  """
  @spec netaddr(<<_::8, _::_*8>>)
    :: Generic.t
     | IPv4.t
     | IPv6.t
     | MAC_48.t
     | {:error, :einval}
  def netaddr(address),
    do: netaddr(address, byte_size(address) * 8)

  @doc """
  Identical to `netaddr/1`, but returns `{:ok, value}` on
  success instead of just `value`.

  ## Examples

      iex> NetAddr.netaddr_2(<<1, 2, 3, 4, 5, 6>>)
      {:ok, %NetAddr.MAC_48{address: <<1, 2, 3, 4, 5, 6>>, length: 48}}

      iex> NetAddr.netaddr_2(<<1, 2, 3, 4, 5>>)
      {:ok, %NetAddr.Generic{address: <<1, 2, 3, 4, 5>>, length: 40}}
  """
  @spec netaddr_2(<<_::8, _::_*8>>)
    :: { :ok,
         Generic.t
       | IPv4.t
       | IPv6.t
       | MAC_48.t
       }
     | {:error, :einval}
  def netaddr_2(address) do
    address
    |> netaddr(byte_size(address) * 8)
    |> wrap_result
  end

  @doc """
  Constructs a `t:NetAddr.t/0` struct given a network
  address binary and an address length.
  """
  @spec netaddr(<<_::8, _::_*8>>, pos_integer)
    :: Generic.t
     | IPv4.t
     | IPv6.t
     | MAC_48.t
     | {:error, :einval}
  def netaddr(address, address_length)
      when byte_size(address) == @ipv4_size
       and address_length in 0..(@ipv4_size * 8),
    do: %IPv4{address: address, length: address_length}

  def netaddr(address, address_length)
      when byte_size(address) == @mac_48_size
       and address_length in 0..(@mac_48_size * 8),
    do: %MAC_48{address: address, length: address_length}

  def netaddr(address, address_length)
      when byte_size(address) == @ipv6_size
       and address_length in 0..(@ipv6_size * 8),
    do: %IPv6{address: address, length: address_length}

  def netaddr(address, address_length)
      when address_length in 0..(byte_size(address) * 8),
    do: %Generic{address: address, length: address_length}

  def netaddr(_, _),
    do: {:error, :einval}

  @doc """
  Identical to `netaddr/2`, but returns `{:ok, value}` on
  success instead of just `value`.

  ## Examples

  iex> NetAddr.netaddr_2(<<1,2,3,4>>, 16)
  {:ok, %NetAddr.IPv4{address: <<1,2,3,4>>, length: 16}}

  iex> NetAddr.netaddr_2(<<1,2,3,4>>, 33)
  {:error, :einval}
  """
  @spec netaddr_2(<<_::8, _::_*8>>, pos_integer)
    :: { :ok,
         Generic.t
       | IPv4.t
       | IPv6.t
       | MAC_48.t
       }
     | {:error, :einval}
  def netaddr_2(address, address_length),
    do: wrap_result netaddr(address, address_length)

  @doc """
  Explicitly constructs a `t:Generic.t/0` struct.

  ## Examples

      iex> NetAddr.netaddr(<<1, 2, 3, 4, 5, 6>>, 48, 6)
      %NetAddr.Generic{address: <<1, 2, 3, 4, 5, 6>>, length: 48}

      iex> NetAddr.netaddr(<<1, 2, 3, 4, 5>>, 48, 6)
      %NetAddr.Generic{address: <<0, 1, 2, 3, 4, 5>>, length: 48}
  """
  @spec netaddr(binary, non_neg_integer, pos_integer)
    :: Generic.t
  def netaddr(address, address_length, size_in_bytes)
      when address_length in 0..(size_in_bytes * 8)
  do
    embedded_address =
      Vector.embed(address, size_in_bytes)

    %Generic{
      address: embedded_address,
      length: address_length
    }
  end

  @doc """
  Identical to `netaddr/3`, but returns `{:ok, value}` on
  success instead of just `value`.

  ## Examples

      iex> NetAddr.netaddr_2(<<1, 2, 3, 4, 5, 6>>, 48, 6)
      {:ok, %NetAddr.Generic{address: <<1, 2, 3, 4, 5, 6>>, length: 48}}

      iex> NetAddr.netaddr_2(<<1, 2, 3, 4, 5>>, 48, 6)
      {:ok, %NetAddr.Generic{address: <<0, 1, 2, 3, 4, 5>>, length: 48}}
  """
  @spec netaddr_2(binary, non_neg_integer, pos_integer)
    :: {:ok, Generic.t}
  def netaddr_2(address, address_length, size_in_bytes) do
    address
    |> netaddr(address_length, size_in_bytes)
    |> wrap_result
  end


  ###################### Conversion ########################

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
  @spec length_to_mask(non_neg_integer, pos_integer)
    :: binary
  def length_to_mask(address_length, mask_length_in_bytes)
      when address_length <= (mask_length_in_bytes * 8)
  do
    ones = bsl(1, address_length) - 1
    mask_length_in_bits = mask_length_in_bytes * 8
    mask_number =
      ones
      |> bsl(mask_length_in_bits - address_length)

    <<mask_number :: size(mask_length_in_bits)>>
  end

  @doc """
  Converts `address_mask` to an address length.

  ## Examples

      iex> NetAddr.mask_to_length(<<255,255,248,0>>)
      21
  """
  @spec mask_to_length(binary)
    :: non_neg_integer
  def mask_to_length(address_mask) do
    address_mask
    |> :binary.bin_to_list
    |> Enum.map(&Math.Binary.ones/1)
    |> Enum.sum
  end

  @doc """
  Convert `address_mask` to an address length.

  Unlike `mask_to_length/1`, this function returns
  `{:ok, length}`, on success, and `{:error, :einval}`,
  otherwise. In particular, this function rejects a mask
  that contains non-consecutive ones bits.

  ## Examples

      iex> NetAddr.mask_to_length_2(<<255,255,248,0>>)
      {:ok, 21}

      iex> NetAddr.mask_to_length_2(<<14,249,150,22>>)
      {:error, :einval}
  """
  @spec mask_to_length_2(binary)
    :: {:ok, non_neg_integer}
     | {:error, :einval}
  def mask_to_length_2(address_mask)
      when is_binary(address_mask)
  do
    octets = :binary.bin_to_list(address_mask)

    subnet_part =
      Enum.filter(octets, & &1 not in [0, 255])

    if length(subnet_part) > 1 do
      {:error, :einval}
    else
      { :ok,
        octets
        |> Enum.map(&Math.Binary.ones/1)
        |> Enum.sum
      }
    end
  end

  def mask_to_length_2(_),
    do: {:error, :einval}

  defp combine_bytes_into_decimal(bytes),
    do: Math.collapse(bytes, 256)

  defp split_decimal_into_bytes(decimal, byte_count) do
    decimal
    |> Math.expand(256)
    |> Vector.embed(byte_count)
  end

  @doc """
  Converts a `t:NetAddr.t/0` to a list of bytes.

  ## Examples

      iex> NetAddr.ip("192.0.2.3/24")
      ...>   |> NetAddr.netaddr_to_list
      [192, 0, 2, 3]
  """
  @spec netaddr_to_list(NetAddr.t)
    :: [byte]
  def netaddr_to_list(netaddr),
    do: :binary.bin_to_list netaddr.address

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
  @spec aton(binary)
    :: non_neg_integer
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
  @spec ntoa(non_neg_integer, pos_integer)
    :: binary
  def ntoa(decimal, size_in_bytes) do
    decimal
    |> split_decimal_into_bytes(size_in_bytes)
    |> :binary.list_to_bin
  end

  @doc """
  Converts a `t:NetAddr.t/0` to a
  [Range.t/0](http://elixir-lang.org/docs/stable/elixir/Range.html#t:t/0).

  ## Examples

      iex> NetAddr.netaddr_to_range NetAddr.ip("198.51.100.0/24")
      3325256704..3325256959
  """
  @spec netaddr_to_range(NetAddr.t)
    :: Range.t
  def netaddr_to_range(netaddr) do
    a = aton first_address(netaddr).address
    b = aton  last_address(netaddr).address

    a..b
  end

  defp _range_to_netaddr(
    a.._ = range,
    size_in_bytes,
    struct
  ) do
    subtract = fn(x, y) -> x - y end
    count = Enum.count range
    new_length =
      (size_in_bytes * 8)
      |> subtract.(Math.Information.log_2(count))
      |> trunc

    %{struct |
      address: ntoa(a, size_in_bytes),
      length: new_length
    }
  end

  @doc """
  Converts `range` to a `t:NetAddr.t/0` given an address
  size hint.

  ## Examples

      iex> NetAddr.range_to_netaddr 3325256704..3325256959, 4
      %NetAddr.IPv4{address: <<198, 51, 100, 0>>, length: 24}
  """
  @spec range_to_netaddr(Range.t, pos_integer)
    :: NetAddr.t
  def range_to_netaddr(range, @ipv4_size = size_in_bytes),
    do: _range_to_netaddr(range, size_in_bytes, %IPv4{})

  def range_to_netaddr(range, @mac_48_size = size_in_bytes),
    do: _range_to_netaddr(range, size_in_bytes, %MAC_48{})

  def range_to_netaddr(range, @ipv6_size = size_in_bytes),
    do: _range_to_netaddr(range, size_in_bytes, %IPv6{})

  def range_to_netaddr(range, size_in_bytes),
    do: _range_to_netaddr(range, size_in_bytes, %Generic{})


  @type sexdectet :: 0..65535

  @type ipv4_tuple
    :: {byte, byte, byte, byte}

  @type ipv6_tuple
    :: { sexdectet,
         sexdectet,
         sexdectet,
         sexdectet,
         sexdectet,
         sexdectet,
         sexdectet,
         sexdectet
       }

  @type erl_ip
    :: ipv4_tuple
     | ipv6_tuple

  @doc """
  Constructs a `t:NetAddr.t/0` struct given an Erlang/OTP
  IP address tuple.

  ## Examples

      iex> NetAddr.erl_ip_to_netaddr({192, 0, 2, 1})
      {:ok, %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 32}}

      iex> NetAddr.erl_ip_to_netaddr({0x2001, 0xdb8, 0, 0, 0, 0, 0, 1})
      {:ok, %NetAddr.IPv6{address: <<0x2001::16, 0xdb8::16, 0::5*16, 1::16>>, length: 128}}
  """
  @spec erl_ip_to_netaddr(erl_ip)
    :: {:ok, NetAddr.t}
     | {:error, :einval}
  def erl_ip_to_netaddr(erl_ip)

  def erl_ip_to_netaddr(
    {o1, o2, o3, o4} = erl_ip
  )   when o1 in 0..255
       and o2 in 0..255
       and o3 in 0..255
       and o4 in 0..255
  do
    erl_ip
    |> Tuple.to_list
    |> :binary.list_to_bin
    |> NetAddr.netaddr_2
  end

  def erl_ip_to_netaddr(
    {s1, s2, s3, s4, s5, s6, s7, s8} = erl_ip
  )   when s1 in 0..65535
       and s2 in 0..65535
       and s3 in 0..65535
       and s4 in 0..65535
       and s5 in 0..65535
       and s6 in 0..65535
       and s7 in 0..65535
       and s8 in 0..65535
  do
    erl_ip
    |> Tuple.to_list
    |> Enum.flat_map(&Math.expand(&1, 256, 2))
    |> :binary.list_to_bin
    |> NetAddr.netaddr_2
  end

  @doc """
  Constructs an Erlang/OTP IP address tuple given a
  `t:NetAddr.t/0`.

  ## Examples

  iex> NetAddr.netaddr_to_erl_ip NetAddr.ip("192.0.2.1")
  {192, 0, 2, 1}

  iex> NetAddr.netaddr_to_erl_ip NetAddr.ip("2001:db8::1")
  {0x2001, 0xdb8, 0, 0, 0, 0, 0, 1}
  """
  @spec netaddr_to_erl_ip(NetAddr.t)
    :: {:ok, erl_ip}
     | {:error, :einval}
  def netaddr_to_erl_ip(netaddr)

  def netaddr_to_erl_ip(
    %NetAddr.IPv4{address: address, length: 32}
  ) do
    address
    |> :binary.bin_to_list
    |> List.to_tuple
  end

  def netaddr_to_erl_ip(
    %NetAddr.IPv6{address: address, length: 128}
  ) do
    address
    |> :binary.bin_to_list
    |> Math.collapse(256)
    |> Math.expand(65536)
    |> List.to_tuple
  end

  def netaddr_to_erl_ip(_),
    do: {:error, :einval}

  @doc """
  Converts a `t:NetAddr.t/0` to a format suitable for DNS
  PTR records.

  ## Examples

  iex> NetAddr.netaddr_to_ptr NetAddr.ip("192.0.2.1")
  {:ok, "1.2.0.192.in-addr.arpa"}

  iex> NetAddr.netaddr_to_ptr NetAddr.ip("2001:db8::1")
  {:ok, "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa"}
  """
  @spec netaddr_to_ptr(NetAddr.t)
    :: {:ok, String.t}
     | {:error, :einval}
  def netaddr_to_ptr(netaddr)

  def netaddr_to_ptr(%NetAddr.IPv4{} = address) do
    address
    |> netaddr_to_list
    |> Enum.reverse
    |> Enum.join(".")
    |> String.replace_suffix("", ".in-addr.arpa")
    |> wrap_result
  end

  def netaddr_to_ptr(%NetAddr.IPv6{address: address}) do
    address
    |> Base.encode16
    |> String.reverse
    |> String.downcase
    |> String.split("", trim: true)
    |> Enum.join(".")
    |> String.replace_suffix("", ".ip6.arpa")
    |> wrap_result
  end

  def netaddr_to_ptr(_),
    do: {:error, :einval}

  @doc """
  Convert a DNS PTR record name to a `t:NetAddr.t/0`.

  ## Examples

  iex> NetAddr.ptr_to_netaddr "1.2.0.192.in-addr.arpa"
  {:ok, %NetAddr.IPv4{address: <<192,0,2,1>>, length: 32}}

  iex> NetAddr.ptr_to_netaddr "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa"
  {:ok, %NetAddr.IPv6{address: <<0x2001::2*8,0xdb8::2*8,0::11*8,1>>, length: 128}}
  """
  @spec ptr_to_netaddr(String.t)
    :: {:ok, NetAddr.t}
     | {:error, :einval}
  def ptr_to_netaddr(ptr_name)

  def ptr_to_netaddr(ptr_name) do
    cond do
      ptr_name =~ ~r/\.in-addr\.arpa$/ ->
        ptr_name
        |> String.trim
        |> String.replace_suffix(".in-addr.arpa", "")
        |> String.split(".", parts: 4)
        |> Enum.reverse
        |> Enum.join(".")
        |> NetAddr.ip_2

      ptr_name =~ ~r/\.ip6\.arpa$/ ->
        with {:ok, bin} <-
               ptr_name
               |> String.trim
               |> String.replace_suffix(".ip6.arpa", "")
               |> String.split(".", parts: 32)
               |> Enum.reverse
               |> Enum.join
               |> String.upcase
               |> Base.decode16,

          do: NetAddr.netaddr_2(bin)
    end
  end

  @doc ~S"""
  Convert IPv4 `netaddr` to a regular expression.

  ## Examples

      iex> NetAddr.netaddr_to_regex NetAddr.ip("192.0.2.0/23")
      ~r/\b192\.0\.[2-3]\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\b/

      iex> NetAddr.netaddr_to_regex NetAddr.ip("192.0.64.0/17")
      ~r/\b192\.0\.([0-9]|[1-9][0-9]|1[0-1][0-9]|12[0-7])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\b/
  """
  @spec netaddr_to_regex(NetAddr.IPv4.t)
    :: Regex.t
  def netaddr_to_regex(netaddr)

  def netaddr_to_regex(%NetAddr.IPv4{} = netaddr) do
    first =
      netaddr
      |> first_address
      |> netaddr_to_list

    last =
      netaddr
      |> last_address
      |> netaddr_to_list

    first
    |> Enum.zip(last)
    |> Enum.map(fn {a, b} -> a..b end)
    |> Enum.map(&Utility.range_to_regex/1)
    |> Enum.join("\\.")
    |> String.replace_prefix("", "\\b")
    |> String.replace_suffix("", "\\b")
    |> Regex.compile!
  end

  #################### Pretty Printing #####################

  @doc """
  Returns a human-readable string for the address part of
  `netaddr`.

  ## Examples

      iex> NetAddr.address NetAddr.ip("192.0.2.1/24")
      "192.0.2.1"

      iex> NetAddr.address NetAddr.netaddr(<<1, 2, 3, 4, 5>>)
      "0x0102030405"
  """
  @spec address(NetAddr.t)
    :: String.t
  def address(netaddr),
    do: NetAddr.Representation.address netaddr

  @doc """
  Returns a new `t:NetAddr.t/0` with the first address in
  `netaddr`.

  ## Examples

      iex> NetAddr.first_address NetAddr.ip("192.0.2.1/24")
      %NetAddr.IPv4{address: <<192, 0, 2, 0>>, length: 24}
  """
  @spec first_address(NetAddr.t)
    :: NetAddr.t
  def first_address(netaddr) do
    size  = byte_size netaddr.address
    mask  = length_to_mask(netaddr.length, size)
    first = apply_mask(netaddr.address, mask)

    %{netaddr | address: first}
  end

  @doc """
  Returns a new `t:NetAddr.t/0` with the last address in
  `netaddr`.

  ## Examples

      iex> NetAddr.last_address NetAddr.ip("192.0.2.1/24")
      %NetAddr.IPv4{address: <<192, 0, 2, 255>>, length: 24}
  """
  @spec last_address(NetAddr.t)
    :: NetAddr.t
  def last_address(netaddr) do
    size = byte_size netaddr.address
    mask = length_to_mask(netaddr.length, size)

    decimal  = trunc :math.pow(2, size*8) - 1
    all_ones = ntoa(decimal, size)

    inverse_mask = Vector.bit_xor(mask, all_ones)

    last =
      first_address(netaddr).address
      |> Vector.bit_or(inverse_mask)

    %{netaddr | address: last}
  end

  @doc """
  Returns a human-readable string for the last address in
  `ipv4_netaddr`.

  ## Examples

      iex> NetAddr.broadcast NetAddr.ip("192.0.2.1/24")
      "192.0.2.255"
  """
  @spec broadcast(IPv4.t)
    :: String.t
  def broadcast(ipv4_netaddr)
  def broadcast(%IPv4{} = ipv4_netaddr) do
    ipv4_netaddr
    |> last_address
    |> address
  end

  @doc """
  Returns a human-readable string for the first address in
  `netaddr`.

  ## Examples

      iex> NetAddr.network NetAddr.ip("192.0.2.1/24")
      "192.0.2.0"
  """
  @spec network(NetAddr.t)
    :: String.t
  def network(netaddr) do
    netaddr
    |> first_address
    |> address
  end

  @doc """
  Returns a human-readable CIDR for the first address in
  `netaddr`.

  ## Examples

      iex> NetAddr.prefix %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}
      "192.0.2.0/24"

      iex> NetAddr.prefix %NetAddr.Generic{address: <<1, 2, 3, 4, 5>>, length: 32}
      "0x0102030400/32"
  """
  @spec prefix(NetAddr.t)
    :: String.t
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
  @spec subnet_mask(IPv4.t)
    :: String.t
  def subnet_mask(ipv4_netaddr)

  def subnet_mask(%IPv4{address: address, length: len}) do
    size = byte_size address
    mask = length_to_mask(len, size)

    address netaddr(mask, len)
  end

  @doc """
  Returns a human-readable CIDR or pseudo-CIDR for
  `netaddr`.

  This is like `NetAddr.prefix/1` except host bits are not
  set to zero. All `String.Chars` implementations call this
  function.

  ## Examples

      iex> NetAddr.netaddr_to_string %NetAddr.Generic{address: <<1, 2, 3, 4, 5>>, length: 32}
      "0x0102030405/32"
  """
  @spec netaddr_to_string(NetAddr.t)
    :: String.t
  def netaddr_to_string(netaddr),
    do: "#{address(netaddr)}/#{address_length(netaddr)}"


  ######################## Parsing #########################

  defp ip_address_string_to_bytes(ip_address_string) do
    # We replace leading zeroes at word boundaries here
    # because `:inet.parse_address/1` processes integers
    # with leading zeroes as octal, and we want decimal,
    # instead.
    #
    ip_address_list =
      ip_address_string
      |> String.replace(~r/\b0*(\d+)/, "\\1")
      |> :binary.bin_to_list

    with {:ok, tuple} <-
           :inet.parse_address(ip_address_list)
    do
      case Tuple.to_list tuple do
        byte_list when length(byte_list) == 4 ->
          {:ok, byte_list}

        word_list when length(word_list) == 8 ->
          byte_list =
            Enum.flat_map word_list,
              &split_decimal_into_bytes(&1, 2)

          {:ok, byte_list}
      end
    end
  end

  defp count_bits_in_binary(binary),
    do: byte_size(binary) * 8

  defp get_length_from_split_residue(split_residue) do
    case split_residue do
      [] ->
        nil

      [ip_length_string] ->
        try do
          String.to_integer ip_length_string

        rescue
          _ in ArgumentError ->
            nil
        end
    end
  end

  @doc """
  Parses `ip_string` as an IPv4/IPv6 address or CIDR,
  returning a `t:IPv4.t/0` or `t:IPv6.t/0` as appropriate.

  ## Examples

      iex> NetAddr.ip "192.0.2.1"
      %NetAddr.IPv4{address: <<192,0,2,1>>, length: 32}

      iex> NetAddr.ip "192.0.2.1/24"
      %NetAddr.IPv4{address: <<192,0,2,1>>, length: 24}

      iex> NetAddr.ip "fe80::c101"
      %NetAddr.IPv6{address: <<0xfe,0x80,0::12*8,0xc1,0x01>>, length: 128}

      iex> NetAddr.ip "fe80::c101/64"
      %NetAddr.IPv6{address: <<0xfe,0x80,0::12*8,0xc1,0x01>>, length: 64}

      iex> NetAddr.ip "blarg"
      {:error, :einval}
  """
  @spec ip(String.t)
    :: IPv4.t
     | IPv6.t
     | {:error, :einval}
  def ip(ip_string) do
    [ip_address_string | split_residue] =
      String.split(ip_string, "/", parts: 2)

    ip_address_length =
      get_length_from_split_residue(split_residue)

    ip(ip_address_string, ip_address_length)
  end

  @doc """
  Identical to `ip/1`, but returns `{:ok, value}` on
  success instead of just `value`.

  ## Examples

      iex> NetAddr.ip_2 "192.0.2.1"
      {:ok, %NetAddr.IPv4{address: <<192,0,2,1>>, length: 32}}

      iex> NetAddr.ip_2 "192.0.2.1/24"
      {:ok, %NetAddr.IPv4{address: <<192,0,2,1>>, length: 24}}

      iex> NetAddr.ip_2 "fe80::c101"
      {:ok, %NetAddr.IPv6{address: <<0xfe,0x80,0::12*8,0xc1,0x01>>, length: 128}}

      iex> NetAddr.ip_2 "fe80::c101/64"
      {:ok, %NetAddr.IPv6{address: <<0xfe,0x80,0::12*8,0xc1,0x01>>, length: 64}}

      iex> NetAddr.ip_2 "blarg"
      {:error, :einval}
  """
  @spec ip_2(String.t)
    :: {:ok, IPv4.t|IPv4.t}
     | {:error, :einval}
  def ip_2(ip_string),
    do: wrap_result ip(ip_string)

  @doc """
  Parses `ip_address_string` with the given address length
  or `ip_mask_string`.

  ## Examples

      iex> NetAddr.ip "0.0.0.0", 0
      %NetAddr.IPv4{address: <<0, 0, 0, 0>>, length: 0}

      iex> NetAddr.ip "192.0.2.1", 24
      %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}

      iex> NetAddr.ip "192.0.2.1", "255.255.255.0"
      %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}

      iex> NetAddr.ip "fe80:0:c100::c401", 64
      %NetAddr.IPv6{address: <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>, length: 64}

      iex> NetAddr.ip "blarg", 32
      {:error, :einval}

      iex> NetAddr.ip "192.0.2.010"
      %NetAddr.IPv4{address: <<192, 0, 2, 10>>, length: 32}

      iex> NetAddr.ip "192.0.2.1/33"
      {:error, :einval}
  """
  @spec ip(String.t, nil)
    :: IPv4.t
     | IPv6.t
     | {:error, :einval}
  @spec ip(String.t, String.t)
    :: IPv4.t
     | IPv6.t
     | {:error, :einval}
  @spec ip(String.t, non_neg_integer)
    :: IPv4.t
     | IPv6.t
     | {:error, :einval}
  def ip(ip_address_string, ip_mask_string_or_length)

  def ip(ip_address_string, ip_mask_string)
      when is_binary(ip_mask_string)
  do
    with %{address: ip_mask} <- ip(ip_mask_string, nil),
      do: ip(ip_address_string, mask_to_length(ip_mask))
  end

  def ip(ip_address_string, ip_address_length0)
      when is_integer(ip_address_length0)
       and ip_address_length0 in 0..(@ipv4_size * 8)
        or ip_address_length0 in 0..(@ipv6_size * 8)
        or ip_address_length0 == nil
  do
    with {:ok, ip_bytes} <-
           ip_address_string_to_bytes(ip_address_string)
    do
      ip_binary = :binary.list_to_bin(ip_bytes)

      ip_address_length =
        ip_address_length0 ||
          count_bits_in_binary(ip_binary)

      netaddr(ip_binary, ip_address_length)
    end
  end

  @doc """
  Identical to `ip/2`, but returns `{:ok, value}` on
  success instead of just `value`.

  ## Examples

      iex> NetAddr.ip_2 "0.0.0.0", 0
      {:ok, %NetAddr.IPv4{address: <<0, 0, 0, 0>>, length: 0}}

      iex> NetAddr.ip_2 "192.0.2.1", 24
      {:ok, %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}}

      iex> NetAddr.ip_2 "192.0.2.1", "255.255.255.0"
      {:ok, %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}}

      iex> NetAddr.ip_2 "192.0.2.1", "14.249.150.22"
      {:error, :einval}

      iex> NetAddr.ip_2 "fe80:0:c100::c401", 64
      {:ok, %NetAddr.IPv6{address: <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>, length: 64}}

      iex> NetAddr.ip_2 "blarg", 32
      {:error, :einval}
  """
  @spec ip_2(String.t, nil)
    :: {:ok, IPv4.t|IPv6.t}
     | {:error, :einval}
  @spec ip_2(String.t, String.t)
    :: {:ok, IPv4.t|IPv6.t}
     | {:error, :einval}
  @spec ip_2(String.t, non_neg_integer)
    :: {:ok, IPv4.t|IPv6.t}
     | {:error, :einval}
  def ip_2(ip_address_string, ip_mask_string)
      when is_binary(ip_mask_string)
  do
    with %{address: ip_mask} <- ip(ip_mask_string),

         {:ok, length} <- mask_to_length_2(ip_mask),

      do: ip_2(ip_address_string, length)
  end

  def ip_2(ip_address_string, length)
      when is_integer(length)
       and length >= 0
  do
    ip_address_string
    |> ip(length)
    |> wrap_result
  end

  defp _parse_mac_48(<<>>, {[], acc}) do
    # If the string is consumed and the current byte is
    # empty, return the accumulator
    :binary.list_to_bin acc
  end

  defp _parse_mac_48(<<>>, {byte_acc, acc}) do
    # If the string is consumed and the current byte is not
    # empty, append the current byte and return the
    # accumulator
    byte = Math.collapse(byte_acc, 16)

    :binary.list_to_bin acc ++ [byte]
  end

  defp _parse_mac_48(<<string::bytes>>, {byte_acc, acc})
      when length(byte_acc) == 2
  do
    # When the current byte contains two characters, combine
    # and append them
    byte = Math.collapse(byte_acc, 16)

    _parse_mac_48(string, {[], acc ++ [byte]})
  end

  defp _parse_mac_48(<<head, tail::binary>>, {[], acc})
      when head in ':-. '
  do
    # When a new delimiter is found and the current byte is
    # empty, consume tail
    _parse_mac_48(tail, {[], acc})
  end
  defp _parse_mac_48(<<head, tail::binary>>, {byte_acc, acc})
      when head in ':-. '
  do
    # When a new delimiter is found, append the current byte
    # to the accumulator
    byte = Math.collapse(byte_acc, 16)

    _parse_mac_48(tail, {[], acc ++ [byte]})
  end
  defp _parse_mac_48(<<head, tail::binary>>, {byte_acc, acc})
      when head in ?0..?9
        or head in ?a..?f
        or head in ?A..?F
  do
    # Convert hexadecimal character to decimal and append it
    # to the current byte
    {nibble, _} = Integer.parse(<<head>>, 16)

    _parse_mac_48(tail, {byte_acc ++ [nibble], acc})
  end
  defp _parse_mac_48(<<_, tail::binary>>, {byte_acc, acc})
  do
    # When no other clause matches, blindly consume tail
    _parse_mac_48(tail, {byte_acc, acc})
  end

  defp parse_mac_48(string),
    do: _parse_mac_48(string, {[], []})

  @doc """
  Parses `mac_string`, returning a `t:MAC_48.t/0`.

  For manifest reasons, the corresponding parser may be
  robust to the point of returning incorrect results.
  *Caveat emptor*.

  ## Examples

      iex> NetAddr.mac_48 "01:23:45:67:89:AB"
      %NetAddr.MAC_48{address: <<0x01,0x23,0x45,0x67,0x89,0xab>>, length: 48}

      iex> NetAddr.mac_48 "01-23-45-67-89-AB"
      %NetAddr.MAC_48{address: <<0x01,0x23,0x45,0x67,0x89,0xab>>, length: 48}

      iex> NetAddr.mac_48 "0123456789aB"
      %NetAddr.MAC_48{address: <<0x01,0x23,0x45,0x67,0x89,0xab>>, length: 48}

      iex> NetAddr.mac_48 "01 23 45 67 89 AB"
      %NetAddr.MAC_48{address: <<0x01,0x23,0x45,0x67,0x89,0xab>>, length: 48}

      iex> NetAddr.mac_48 "\\"0fF:33-C0.Ff   33 \\""
      %NetAddr.MAC_48{address: <<0x0f, 0xf, 0x33, 0xc0, 0xff, 0x33>>, length: 48}

      iex> NetAddr.mac_48 "1:2:3:4:5:6"
      %NetAddr.MAC_48{address: <<1,2,3,4,5,6>>, length: 48}

      iex> NetAddr.mac_48 "01-23-45-67-89-ag"
      %NetAddr.MAC_48{address: <<0x01,0x23,0x45,0x67,0x89,0xa>>, length: 48}

      iex> NetAddr.mac_48 "123456789aB"
      %NetAddr.MAC_48{address: <<0x12,0x34,0x56,0x78,0x9a,0xb>>, length: 48}

      iex> NetAddr.mac_48 "blarg"
      {:error, :einval}
  """
  @spec mac_48(binary)
    :: MAC_48.t
     | {:error, :einval}
  def mac_48(mac_string) do
    mac_string
    |> String.replace(~r/^\s*/, "")
    |> String.replace(~r/\s*$/, "")
    |> parse_mac_48
    |> netaddr(48)
  end

  @doc """
  Identical to `mac_48/1`, but returns `{:ok, value}` on
  success instead of just `value`.

  ## Examples

      iex> NetAddr.mac_48_2 "01:23:45:67:89:AB"
      {:ok, %NetAddr.MAC_48{address: <<0x01,0x23,0x45,0x67,0x89,0xab>>, length: 48}}

      iex> NetAddr.mac_48_2 "01-23-45-67-89-AB"
      {:ok, %NetAddr.MAC_48{address: <<0x01,0x23,0x45,0x67,0x89,0xab>>, length: 48}}

      iex> NetAddr.mac_48_2 "0123456789aB"
      {:ok, %NetAddr.MAC_48{address: <<0x01,0x23,0x45,0x67,0x89,0xab>>, length: 48}}

      iex> NetAddr.mac_48_2 "01 23 45 67 89 AB"
      {:ok, %NetAddr.MAC_48{address: <<0x01,0x23,0x45,0x67,0x89,0xab>>, length: 48}}

      iex> NetAddr.mac_48_2 "\\"0fF:33-C0.Ff   33 \\""
      {:ok, %NetAddr.MAC_48{address: <<0x0f, 0xf, 0x33, 0xc0, 0xff, 0x33>>, length: 48}}

      iex> NetAddr.mac_48_2 "1:2:3:4:5:6"
      {:ok, %NetAddr.MAC_48{address: <<1,2,3,4,5,6>>, length: 48}}

      iex> NetAddr.mac_48_2 "01-23-45-67-89-ag"
      {:ok, %NetAddr.MAC_48{address: <<0x01,0x23,0x45,0x67,0x89,0xa>>, length: 48}}

      iex> NetAddr.mac_48_2 "123456789aB"
      {:ok, %NetAddr.MAC_48{address: <<0x12,0x34,0x56,0x78,0x9a,0xb>>, length: 48}}

      iex> NetAddr.mac_48_2 "blarg"
      {:error, :einval}
  """
  @spec mac_48_2(binary)
    :: {:ok, MAC_48.t}
     | {:error, :einval}
  def mac_48_2(mac_string),
    do: wrap_result mac_48(mac_string)


  ####################### Utilities ########################

  @doc """
  Bitwise ANDs two address binaries, returning the result.

  ## Examples

      iex> NetAddr.apply_mask <<192,0,2,1>>, <<255,255,255,0>>
      <<192, 0, 2, 0>>

      iex> NetAddr.apply_mask <<192,0,2,1>>, <<14,249,150,22>>
      <<0,0,2,0>>
  """
  @spec apply_mask(binary, binary)
    :: binary
  def apply_mask(address, mask)
      when is_binary(address)
       and is_binary(mask),
    do: Vector.bit_and(address, mask)

  @doc """
  Tests whether `netaddr` contains `netaddr2`, up to
  equality.

  ## Examples

      iex> NetAddr.ip("192.0.2.0/24")
      ...>   |> NetAddr.contains?(NetAddr.ip("192.0.2.0/25"))
      true

      iex> NetAddr.ip("192.0.2.0/24")
      ...>   |> NetAddr.contains?(NetAddr.ip("192.0.2.0/24"))
      true

      iex> NetAddr.ip("192.0.2.0/25")
      ...>   |> NetAddr.contains?(NetAddr.ip("192.0.2.0/24"))
      false

      iex> NetAddr.ip("192.0.2.0/25")
      ...>   |> NetAddr.contains?(NetAddr.ip("192.0.2.128/25"))
      false

      iex> NetAddr.ip("192.0.2.3/31")
      ...>   |> NetAddr.contains?(NetAddr.ip("192.0.2.2"))
      true
  """
  @spec contains?(NetAddr.t, NetAddr.t)
    :: boolean
     | none
  def contains?(netaddr1, netaddr2)

  def contains?(
    %{address: _, length: l1} = n1,
    %{address: _, length: l2} = n2
  ) do
    l1 <= l2
    and first_address(n1) ==
          first_address(address_length(n2, l1))
  end

  @doc """
  Tests whether `netaddr` has length equal to its size in
  bits.

  ## Examples

      iex> NetAddr.is_host_address NetAddr.ip("0.0.0.0/0")
      false

      iex> NetAddr.is_host_address NetAddr.ip("192.0.2.1")
      true

      iex> NetAddr.is_host_address NetAddr.ip("fe80:0:c100::c401")
      true

      iex> NetAddr.is_host_address NetAddr.ip("::/0")
      false
  """
  @spec is_host_address(NetAddr.t)
    :: boolean
  def is_host_address(netaddr)

  def is_host_address(
    %{address: _, length: _} = netaddr
  ) do
    (NetAddr.address_size(netaddr) * 8) ==
      NetAddr.address_length(netaddr)
  end

  @doc """
  Tests whether `string` can be parsed as an IP address.

  ## Examples

      iex> NetAddr.is_ip "not an IP address"
      false

      iex> NetAddr.is_ip %{}
      false

      iex> NetAddr.is_ip "0.0.0.0/0"
      true

      iex> NetAddr.is_ip "192.0.2.1"
      true

      iex> NetAddr.is_ip "fe80:0:c100::c401"
      true

      iex> NetAddr.is_ip "::/0"
      true
  """
  @spec is_ip(String.t)
    :: boolean
  def is_ip(string)
      when is_binary(string),
    do: NetAddr.ip(string) != {:error, :einval}

  def is_ip(_),
    do: false

  @doc """
  Tests whether `string` can be parsed as an IPv4 address.

  ## Examples

      iex> NetAddr.is_ipv4 "not an IP address"
      false

      iex> NetAddr.is_ip %{}
      false

      iex> NetAddr.is_ipv4 "0.0.0.0/0"
      true

      iex> NetAddr.is_ipv4 "192.0.2.1"
      true

      iex> NetAddr.is_ipv4 "fe80:0:c100::c401"
      false

      iex> NetAddr.is_ipv4 "::/0"
      false
  """
  @spec is_ipv4(String.t)
    :: boolean
  def is_ipv4(string)
      when is_binary(string)
  do
    case NetAddr.ip(string) do
      %NetAddr.IPv4{} -> true
                    _ -> false
    end
  end

  def is_ipv4(_),
    do: false

  @doc """
  Tests whether `string` can be parsed as an IPv6 address.

  ## Examples

      iex> NetAddr.is_ipv6 "not an IP address"
      false

      iex> NetAddr.is_ip %{}
      false

      iex> NetAddr.is_ipv6 "0.0.0.0/0"
      false

      iex> NetAddr.is_ipv6 "192.0.2.1"
      false

      iex> NetAddr.is_ipv6 "fe80:0:c100::c401"
      true

      iex> NetAddr.is_ipv6 "::/0"
      true
  """
  @spec is_ipv6(String.t)
    :: boolean
  def is_ipv6(string)
      when is_binary(string)
  do
    case NetAddr.ip(string) do
      %NetAddr.IPv6{} -> true
                    _ -> false
    end
  end

  def is_ipv6(_),
    do: false
end


defprotocol NetAddr.Representation do
  @spec address(NetAddr.t, list)
    :: String.t
  def address(netaddr, opts \\ [])
end


defimpl NetAddr.Representation,
    for: NetAddr.IPv4
do
  def address(netaddr, _opts) do
    netaddr.address
    |> :binary.bin_to_list
    |> Enum.join(".")
  end
end


defimpl NetAddr.Representation,
    for: NetAddr.IPv6
do
  defp drop_leading_zeros(string)
      when is_binary string
  do
    with "" <- String.replace(string, ~r/^0*/, ""),
      do: "0"
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


defimpl NetAddr.Representation,
    for: NetAddr.MAC_48
do
  def address(netaddr, opts) do
    delimiter = Keyword.get(opts, :delimiter, ":")

    netaddr.address
    |> :binary.bin_to_list
    |> Enum.map(&Base.encode16(<<&1>>))
    |> Enum.join(delimiter)
  end
end


defimpl NetAddr.Representation,
    for: NetAddr.Generic
do
  def address(netaddr, _opts) do
    hex_with_len =
      netaddr.address
      |> :binary.bin_to_list
      |> Enum.map(&Base.encode16(<<&1>>))
      |> Enum.join("")

    "0x#{hex_with_len}"
  end
end


defimpl String.Chars,
    for: NetAddr.IPv4
do
  import Kernel, except: [to_string: 1]

  def to_string(netaddr),
    do: NetAddr.netaddr_to_string netaddr
end


defimpl String.Chars,
    for: NetAddr.IPv6
do
  import Kernel, except: [to_string: 1]

  def to_string(netaddr),
    do: NetAddr.netaddr_to_string netaddr
end


defimpl String.Chars,
    for: NetAddr.MAC_48
do
  import Kernel, except: [to_string: 1]

  def to_string(netaddr),
    do: NetAddr.address netaddr
end


defimpl String.Chars,
    for: NetAddr.Generic
do
  import Kernel, except: [to_string: 1]

  def to_string(netaddr),
    do: NetAddr.netaddr_to_string netaddr
end
