# Copyright © 2016 Jonathan Storm <the.jonathan.storm@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING.WTFPL file for more details.

defmodule NetAddrTest do
  use ExUnit.Case, async: true
  doctest NetAddr

  test "parses an IPv4 address" do
    netaddr = %NetAddr.IPv4{address: <<192,0,2,1>>, length: 32}

    assert netaddr == NetAddr.ipv4("192.0.2.1")
  end
  test "parses an IPv4 address with length" do
    netaddr = %NetAddr.IPv4{address: <<192,0,2,1>>, length: 24}

    assert netaddr == NetAddr.ipv4("192.0.2.1", 24)
  end
  test "parses IPv4 address and mask" do
    result = %NetAddr.IPv4{address: <<192,0,2,1>>, length: 24}

    assert result == NetAddr.ipv4("192.0.2.1", "255.255.255.0")
  end
  test "fails to parse an empty string" do
    assert_raise ArgumentError, fn -> NetAddr.ipv4("") end
  end

  test "parses IPv4 CIDR" do
    netaddr = %NetAddr.IPv4{address: <<192,0,2,1>>, length: 24}

    assert netaddr == NetAddr.ipv4_cidr("192.0.2.1/24")
  end

  test "converts a length to a mask" do
    assert <<255,255,192,0>> == NetAddr.length_to_mask(18, 4)
  end

  test "converts a mask to a length" do
    assert NetAddr.mask_to_length(<<255,255,192,0>>) == 18
  end

  test "parses an IPv6 address" do
    netaddr = %NetAddr.IPv6{
      address: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>,
      length: 128
    }

    assert netaddr == NetAddr.ipv6("fe80:0:0:0:0:0:0:c101")
  end

  test "parses an IPv6 address with length" do
    netaddr = %NetAddr.IPv6{
      address: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>,
      length: 64
    }

    assert netaddr == NetAddr.ipv6("fe80:0:0:0:0:0:0:c101", 64)
  end

  test "parses IPv6 CIDR" do
    netaddr = %NetAddr.IPv6{address: <<0xfe,0x80, 0::13 * 8, 0x01>>, length: 64}

    assert netaddr == NetAddr.ipv6_cidr("fe80::1/64")
  end

  test "converts an address to a decimal" do
    result = 4311810305
    address = <<1,1,1,1,1>> = <<result::40>>

    assert result == NetAddr.aton(address)
  end

  test "converts a decimal to an address" do
    decimal = 4311810305
    result = <<1,1,1,1,1>> = <<decimal::40>>

    assert result == NetAddr.ntoa(decimal, 5)
  end

  test "returns decimal range for IPv4 netaddr" do
    decimal = 4311810305
    address = <<1,1,1,1,1>> = <<decimal::40>>

    netaddr = %NetAddr.Generic{address: address, length: 32}

    result = (decimal - 1)..(decimal + 254)

    assert result == NetAddr.netaddr_to_range(netaddr)
  end

  test "returns IPv4 netaddr for decimal range" do
    decimal = 4311810304
    address = <<1,1,1,1,0>> = <<decimal::40>>

    result = %NetAddr.Generic{address: address, length: 32}

    range = decimal..(decimal + 255)

    assert result == NetAddr.range_to_netaddr(range, 5)
  end

  test "pretty-prints IPv4 netaddr" do
    result = to_string %NetAddr.IPv4{address: <<192,0,2,1>>, length: 24}

    assert result == "192.0.2.1/24"
  end

  test "pretty-prints IPv4 netaddr network" do
    result = NetAddr.network %NetAddr.IPv4{address: <<192,0,2,1>>, length: 24}

    assert result == "192.0.2.0"
  end

  test "pretty-prints IPv4 netaddr broadcast" do
    result = NetAddr.broadcast %NetAddr.IPv4{address: <<192,0,2,1>>, length: 24}

    assert result == "192.0.2.255"
  end

  test "pretty-prints IPv4 netaddr subnet-mask" do
    result = NetAddr.subnet_mask %NetAddr.IPv4{address: <<192,0,2,1>>, length: 24}

    assert result == "255.255.255.0"
  end

  test "pretty-prints IPv6 netaddr" do
    result =
      %NetAddr.IPv6{
        address: <<0xfe80::2*8, 0::12*8, 0xc1, 0x01>>,
        length: 128

      } |> to_string

    assert result == "fe80::c101/128"
  end

  test "pretty-prints IPv6 netaddr with compressed zeros for only largest group of zeros" do
    result =
      %NetAddr.IPv6{
        address: <<0xfe80::2*8, 0::2*8, 0xc1, 0::10*8, 0x01>>,
        length: 128

      } |> to_string

    assert result == "fe80:0:c100::1/128"
  end

  test "pretty-prints Generic netaddr" do
    result =
      %NetAddr.Generic{
        address: <<1, 2, 3, 4, 5>>,
        length: 40

      } |> to_string

    assert result == "0x0102030405/40"
  end

  test "parses a hyphen-delimited MAC address" do
    result = %NetAddr.MAC_48{
      address: <<0x01,0x23,0x45,0x67,0x89,0xab>>,
      length: 48
    }

    assert result == NetAddr.mac_48("01-23-45-67-89-AB")
  end
  test "parses a different hyphen-delimited MAC address" do
    result = %NetAddr.MAC_48{
      address: <<0xc0,0xff,0x33,0xc0,0xff,0x33>>,
      length: 48
    }

    assert NetAddr.mac_48("C0-FF-33-C0-FF-33") == result
  end
  test "parses a colon-delimited MAC address" do
    result = %NetAddr.MAC_48{
      address: <<0x01,0x23,0x45,0x67,0x89,0xab>>,
      length: 48
    }

    assert result == NetAddr.mac_48("01:23:45:67:89:AB")
  end
  test "parses a space-delimited MAC address" do
    result = %NetAddr.MAC_48{
      address: <<0x01,0x23,0x45,0x67,0x89,0xab>>,
      length: 48
    }

    assert result == NetAddr.mac_48("01 23 45 67 89 AB")
  end
  test "parses a MAC address with lowercase letters" do
    result = %NetAddr.MAC_48{
      address: <<0x01,0x23,0x45,0x67,0x89,0xab>>,
      length: 48
    }

    assert result == NetAddr.mac_48("01-23-45-67-89-ab")
  end
  test "parses a MAC address with single-digit parts" do
    result = %NetAddr.MAC_48{
      address: <<0x01,0x23,0x45,0x67,0x89,0xab>>,
      length: 48
    }

    assert result == NetAddr.mac_48("1-23-45-67-89-ab")
  end
  test "parses a MAC address with no delimiting characters" do
    result = %NetAddr.MAC_48{
      address: <<0x01,0x23,0x45,0x67,0x89,0xab>>,
      length: 48
    }

    assert NetAddr.mac_48("0123456789ab") == result
  end
  test "parses a MAC address with extraneous characters" do
    result = %NetAddr.MAC_48{
      address: <<0x01,0x23,0x45,0x67,0x89,0xab>>,
      length: 48
    }

    assert NetAddr.mac_48("\"0123456789ab \"") == result
  end
  test "does not fail when parsing a MAC address with no delimiting characters and too few digits" do
    result = %NetAddr.MAC_48{
      address: <<0x12,0x34,0x56,0x78,0x9a,0xb>>,
      length: 48
    }

    assert result == NetAddr.mac_48("123456789ab")
  end
  test "does not fail when parsing invalid MAC address" do
    result = %NetAddr.MAC_48{
      address: <<0x01,0x23,0x45,0x67,0x89,0xa>>,
      length: 48
    }

    assert result == NetAddr.mac_48("01-23-45-67-89-ag")
  end

  test "determines that one netaddr contains another" do
    netaddr1 = %NetAddr.IPv4{address: <<192,0,2,0>>, length: 24}
    netaddr2 = %NetAddr.IPv4{address: <<192,0,2,128>>, length: 25}

    assert NetAddr.contains?(netaddr1, netaddr2) == true
  end

  test "determines that one netaddr does not contain another" do
    netaddr1 = %NetAddr.IPv4{address: <<192,0,2,0>>, length: 24}
    netaddr2 = %NetAddr.IPv4{address: <<192,0,2,128>>, length: 25}

    assert NetAddr.contains?(netaddr2, netaddr1) == false
  end

  test "determines that a netaddr contains itself" do
    netaddr = %NetAddr.IPv4{address: <<192,0,2,0>>, length: 24}

    assert NetAddr.contains?(netaddr, netaddr) == true
  end
end
