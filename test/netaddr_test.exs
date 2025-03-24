# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

defmodule NetAddrTest do
  use ExUnit.Case, async: true
  doctest NetAddr

  test "fails to parse an empty string" do
    assert NetAddr.ip("") == {:error, :einval}
  end

  test "converts a length to a mask" do
    assert <<255, 255, 192, 0>> == NetAddr.length_to_mask(18, 4)
  end

  test "converts a mask to a length" do
    assert NetAddr.mask_to_length(<<255, 255, 192, 0>>) == 18
  end

  test "converts an address to a decimal" do
    result = 4_311_810_305
    address = <<1, 1, 1, 1, 1>> = <<result::40>>

    assert result == NetAddr.aton(address)
  end

  test "converts a decimal to an address" do
    decimal = 4_311_810_305
    result = <<1, 1, 1, 1, 1>> = <<decimal::40>>

    assert result == NetAddr.ntoa(decimal, 5)
  end

  test "returns decimal range for IPv4 netaddr" do
    decimal = 4_311_810_305
    address = <<1, 1, 1, 1, 1>> = <<decimal::40>>

    netaddr = %NetAddr.Generic{address: address, length: 32}

    result = (decimal - 1)..(decimal + 254)

    assert result == NetAddr.netaddr_to_range(netaddr)
  end

  test "returns IPv4 netaddr for decimal range" do
    decimal = 4_311_810_304
    address = <<1, 1, 1, 1, 0>> = <<decimal::40>>

    result = %NetAddr.Generic{address: address, length: 32}

    range = decimal..(decimal + 255)

    assert result == NetAddr.range_to_netaddr(range, 5)
  end

  test "pretty-prints IPv4 netaddr" do
    result = to_string(%NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24})

    assert result == "192.0.2.1/24"
  end

  test "pretty-prints IPv4 netaddr network" do
    result = NetAddr.network(%NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24})

    assert result == "192.0.2.0"
  end

  test "pretty-prints IPv4 netaddr broadcast" do
    result = NetAddr.broadcast(%NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24})

    assert result == "192.0.2.255"
  end

  test "pretty-prints IPv4 netaddr subnet-mask" do
    result = NetAddr.subnet_mask(%NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24})

    assert result == "255.255.255.0"
  end

  test "pretty-prints IPv6 netaddr" do
    result =
      %NetAddr.IPv6{
        address: <<0xFE80::2*8, 0::12*8, 0xC1, 0x01>>,
        length: 128
      }
      |> to_string

    assert result == "fe80::c101/128"
  end

  test "pretty-prints IPv6 netaddr with compressed zeros for only largest group of zeros" do
    result =
      %NetAddr.IPv6{
        address: <<0xFE80::2*8, 0::2*8, 0xC1, 0::10*8, 0x01>>,
        length: 128
      }
      |> to_string

    assert result == "fe80:0:c100::1/128"
  end

  test "pretty-prints Generic netaddr" do
    result =
      %NetAddr.Generic{
        address: <<1, 2, 3, 4, 5>>,
        length: 40
      }
      |> to_string

    assert result == "0x0102030405/40"
  end

  test "generates regex matching all of 192.0.2.0/23" do
    cidr = NetAddr.ip("192.0.2.0/23")
    regex = NetAddr.netaddr_to_regex(cidr)

    result =
      cidr
      |> NetAddr.netaddr_to_range()
      |> Enum.map(&NetAddr.ntoa(&1, 4))
      |> Enum.map(&NetAddr.netaddr(&1, 23))

    assert Enum.all?(result, &("#{&1}" =~ regex))
  end

  test "generates regex matching all of 192.0.2.128/25" do
    cidr = NetAddr.ip("192.0.2.128/25")
    regex = NetAddr.netaddr_to_regex(cidr)

    result =
      cidr
      |> NetAddr.netaddr_to_range()
      |> Enum.map(&NetAddr.ntoa(&1, 4))
      |> Enum.map(&NetAddr.netaddr(&1, 25))

    assert Enum.all?(result, &("#{&1}" =~ regex))
  end

  describe "sigils" do
    use NetAddr

    test "~p sigil parses IPv4 addresses" do
      assert ~p"192.0.2.1/24" == %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}
    end

    test "~p sigil parses IPv6 addresses" do
      assert ~p"2001:db8::1" == %NetAddr.IPv6{
               address: <<0x2001::16, 0xDB8::16, 0::5*16, 1::16>>,
               length: 128
             }
    end

    test "~p sigil parses multiple addresses" do
      assert ~p(192.0.2.1/24 2001:db8::1) == [
               %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24},
               %NetAddr.IPv6{address: <<0x2001::16, 0xDB8::16, 0::5*16, 1::16>>, length: 128}
             ]
    end

    test "~IP sigil parses IPv4 addresses" do
      assert ~IP"192.0.2.1/24" == %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}
    end

    test "~IP sigil parses IPv6 addresses" do
      assert ~IP"2001:db8::1" == %NetAddr.IPv6{
               address: <<0x2001::16, 0xDB8::16, 0::5*16, 1::16>>,
               length: 128
             }
    end

    test "~IP sigil parses multiple addresses" do
      assert ~IP(192.0.2.1/24 2001:db8::1) == [
               %NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24},
               %NetAddr.IPv6{address: <<0x2001::16, 0xDB8::16, 0::5*16, 1::16>>, length: 128}
             ]
    end

    test "~MAC sigil parses single MAC address" do
      assert ~MAC"01:23:45:67:89:AB" == %NetAddr.MAC_48{
               address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xAB>>,
               length: 48
             }
    end

    test "~MAC sigil parses MAC address with dashes" do
      assert ~MAC"01-23-45-67-89-AB" == %NetAddr.MAC_48{
               address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xAB>>,
               length: 48
             }
    end

    test "~MAC sigil parses multiple MAC addresses" do
      assert ~MAC(01:23:45:67:89:AB 0f:f3:3c:0f:f3:03) == [
               %NetAddr.MAC_48{address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xAB>>, length: 48},
               %NetAddr.MAC_48{address: <<0x0F, 0xF3, 0x3C, 0x0F, 0xF3, 0x03>>, length: 48}
             ]
    end
  end
end
