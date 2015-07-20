defmodule NetAddrTest do
  use Amrita.Sweet

  fact "parses an IPv4 address" do
    prefix = %NetAddr.Prefix{network: <<192,0,2,1>>, length: 32}

    NetAddr.ipv4("192.0.2.1") |> prefix
  end

  fact "parses an IPv4 address with length" do
    prefix = %NetAddr.Prefix{network: <<192,0,2,0>>, length: 24}

    NetAddr.ipv4("192.0.2.0", 24) |> prefix
  end

  fact "parses an IPv4 address with length and ones in the host portion" do
    prefix = %NetAddr.Prefix{network: <<192,0,2,0>>, length: 24}

    NetAddr.ipv4("192.0.2.1", 24) |> prefix
  end

  fact "parses CIDR" do
    prefix = %NetAddr.Prefix{network: <<192,0,2,0>>, length: 24}

    NetAddr.ipv4_cidr("192.0.2.0/24") |> prefix
  end

  fact "converts a length to a mask" do
    mask = <<255,255,192,0>>

    NetAddr.prefix_length_to_mask(18, 4) |> mask
  end

  fact "converts a mask to a length" do
    NetAddr.mask_to_prefix_length(<<255,255,192,0>>) |> 18
  end

  fact "parses an IPv6 address" do
    prefix = %NetAddr.Prefix{network: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>, length: 128}

    NetAddr.ipv6("fe80:0:0:0:0:0:0:c101") |> prefix
  end

  fact "parses IPv6 prefix" do
    prefix = %NetAddr.Prefix{network: <<0xfe,0x80, 0::14 * 8>>, length: 64}

    NetAddr.ipv6_prefix("fe80::/64") |> prefix
  end

  fact "converts an address to a decimal" do
    result = 4311810305
    address = <<1,1,1,1,1>> = <<result::40>>

    NetAddr.aton(address) |> result
  end

  fact "converts a decimal to an address" do
    decimal = 4311810305
    result = <<1,1,1,1,1>> = <<decimal::40>>

    NetAddr.ntoa(decimal, Math.Binary.bits(decimal)) |> result
  end

  fact "parses IPv4 address and mask" do
    result = %NetAddr.Prefix{network: <<192,0,2,0>>, length: 24}

    NetAddr.ipv4("192.0.2.1", "255.255.255.0") |> result
  end

  fact "pretty-prints IPv4 prefix" do
    %NetAddr.Prefix{network: <<192,0,2,0>>, length: 24}
    |> NetAddr.prefix_to_ipv4_cidr
    |> "192.0.2.0/24"
  end

  fact "converts decimal number to hexadecimal string" do
    NetAddr.decimal_to_hexadecimal_string(0x1a) |> "1A"
  end

  fact "converts uppercase hexadecimal string to decimal number" do
    NetAddr.hexadecimal_string_to_decimal("1A") |> 0x1a
  end

  fact "converts lowercase hexadecimal string to decimal number" do
    NetAddr.hexadecimal_string_to_decimal("1a") |> 0x1a
  end

  fact "converts another lowercase hexadecimal string to decimal number" do
    NetAddr.hexadecimal_string_to_decimal("c0ff33") |> 0xc0ff33
  end

  fact "pretty-prints IPv6 prefix" do
    %NetAddr.Prefix{network: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>, length: 128}
    |> NetAddr.prefix_to_ipv6_prefix_string
    |> "fe80:0:0:0:0:0:0:c101/128"
  end

  fact "pretty-prints IPv6 prefix with compressed zeros" do
    %NetAddr.Prefix{network: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>, length: 128}
    |> NetAddr.prefix_to_ipv6_prefix_string
    |> NetAddr.compress_ipv6_string
    |> "fe80::c101/128"
  end

  fact "pretty-prints IPv6 prefix with compressed zeros for only largest group of zeros" do
    %NetAddr.Prefix{network: <<0xfe,0x80, 0::2 * 8, 0xc1, 0::10 * 8, 0x01>>, length: 128}
    |> NetAddr.prefix_to_ipv6_prefix_string
    |> NetAddr.compress_ipv6_string
    |> "fe80:0:c100::1/128"
  end
end
