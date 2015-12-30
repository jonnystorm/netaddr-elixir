defmodule NetAddrTest do
  use ExUnit.Case, async: true

  test "parses an IPv4 address" do
    prefix = %NetAddr.Prefix{address: <<192,0,2,1>>, length: 32}

    assert prefix == NetAddr.ipv4("192.0.2.1")
  end
  test "parses an IPv4 address with length" do
    prefix = %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}

    assert prefix == NetAddr.ipv4("192.0.2.0", 24)
  end
  test "parses an IPv4 address with length and ones in the host portion" do
    prefix = %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}

    assert prefix == NetAddr.ipv4("192.0.2.1", 24)
  end
  test "parses IPv4 address and mask" do
    result = %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}

    assert result == NetAddr.ipv4("192.0.2.1", "255.255.255.0")
  end
  test "fails to parse an empty string" do
    assert_raise ArgumentError, fn -> NetAddr.ipv4("") end
  end

  test "parses CIDR" do
    prefix = %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}

    assert prefix == NetAddr.ipv4_cidr("192.0.2.0/24")
  end

  test "converts a length to a mask" do
    assert <<255,255,192,0>> == NetAddr.prefix_length_to_mask(18, 4)
  end

  test "converts a mask to a length" do
    assert NetAddr.mask_to_prefix_length(<<255,255,192,0>>) == 18
  end

  test "parses an IPv6 address" do
    prefix = %NetAddr.Prefix{
      address: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>,
      length: 128
    }

    assert prefix == NetAddr.ipv6("fe80:0:0:0:0:0:0:c101")
  end

  test "parses IPv6 prefix" do
    prefix = %NetAddr.Prefix{address: <<0xfe,0x80, 0::14 * 8>>, length: 64}

    assert prefix == NetAddr.ipv6_prefix("fe80::/64")
  end

  test "converts an address to a decimal" do
    result = 4311810305
    address = <<1,1,1,1,1>> = <<result::40>>

    assert result == NetAddr.aton(address)
  end

  test "converts a decimal to an address" do
    decimal = 4311810305
    result = <<1,1,1,1,1>> = <<decimal::40>>

    assert result == NetAddr.ntoa(decimal, Math.Binary.bits(decimal))
  end

  test "pretty-prints IPv4 prefix" do
    result =
      %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}
        |> NetAddr.prefix_to_ipv4

    assert result == "192.0.2.0"
  end

  test "pretty-prints IPv4 prefix as CIDR" do
    result =
      %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}
        |> NetAddr.prefix_to_ipv4_cidr

    assert result == "192.0.2.0/24"
  end

  test "pretty-prints IPv6 prefix" do
    result =
      %NetAddr.Prefix{address: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>, length: 128}
        |> NetAddr.prefix_to_ipv6_prefix_string

    assert result == "fe80:0:0:0:0:0:0:c101/128"
  end

  test "pretty-prints IPv6 prefix with compressed zeros" do
    result =
      %NetAddr.Prefix{address: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>, length: 128}
        |> NetAddr.prefix_to_ipv6_prefix_string
        |> NetAddr.compress_ipv6_string

    assert result == "fe80::c101/128"
  end

  test "pretty-prints IPv6 prefix with compressed zeros for only largest group of zeros" do
    result =
      %NetAddr.Prefix{address: <<0xfe,0x80, 0::2 * 8, 0xc1, 0::10 * 8, 0x01>>, length: 128}
        |> NetAddr.prefix_to_ipv6_prefix_string
        |> NetAddr.compress_ipv6_string

    assert result == "fe80:0:c100::1/128"
  end

  test "parses a hyphen-delimited MAC address" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    assert result == NetAddr.mac("01-23-45-67-89-AB")
  end
  test "parses a different hyphen-delimited MAC address" do
    result = %NetAddr.Prefix{
      address: <<0xc0, 0xff, 0x33, 0xc0, 0xff, 0x33>>,
      length: 48
    }

    assert NetAddr.mac("C0-FF-33-C0-FF-33") == result
  end
  test "parses a colon-delimited MAC address" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    assert result == NetAddr.mac("01:23:45:67:89:AB")
  end
  test "parses a space-delimited MAC address" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    assert result == NetAddr.mac("01 23 45 67 89 AB")
  end
  test "parses a MAC address with lowercase letters" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    assert result == NetAddr.mac("01-23-45-67-89-ab")
  end
  test "parses a MAC address with single-digit parts" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    assert result == NetAddr.mac("1-23-45-67-89-ab")
  end
  test "parses a MAC address with no delimiting characters" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    assert NetAddr.mac("0123456789ab") == result
  end
  test "parses a MAC address with extraneous characters" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    assert NetAddr.mac("\"0123456789ab \"") == result
  end
  test "does not fail when parsing a MAC address with no delimiting characters and too few digits" do
    result = %NetAddr.Prefix{
      address: <<0x12, 0x34, 0x56, 0x78, 0x9a, 0xb>>,
      length: 48
    }

    assert result == NetAddr.mac("123456789ab")
  end
  test "does not fail when parsing invalid MAC address" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xa>>,
      length: 48
    }

    assert result == NetAddr.mac("01-23-45-67-89-ag")
  end

  test "determines that one prefix contains another" do
    prefix1 = %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}
    prefix2 = %NetAddr.Prefix{address: <<192,0,2,128>>, length: 25}

    assert (prefix1 |> NetAddr.contains?(prefix2)) == true
  end
end
