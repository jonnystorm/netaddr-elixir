defmodule NetAddrTest do
  use Amrita.Sweet

  fact "parses an IPv4 address" do
    prefix = %NetAddr.Prefix{address: <<192,0,2,1>>, length: 32}

    NetAddr.ipv4("192.0.2.1") |> prefix
  end
  fact "parses an IPv4 address with length" do
    prefix = %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}

    NetAddr.ipv4("192.0.2.0", 24) |> prefix
  end
  fact "parses an IPv4 address with length and ones in the host portion" do
    prefix = %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}

    NetAddr.ipv4("192.0.2.1", 24) |> prefix
  end
  fact "parses IPv4 address and mask" do
    result = %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}

    NetAddr.ipv4("192.0.2.1", "255.255.255.0") |> result
  end
  fact "fails to parse an empty string" do
    fn -> NetAddr.ipv4("") end |> raises ArgumentError
  end

  fact "parses CIDR" do
    prefix = %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}

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
    prefix = %NetAddr.Prefix{address: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>, length: 128}

    NetAddr.ipv6("fe80:0:0:0:0:0:0:c101") |> prefix
  end

  fact "parses IPv6 prefix" do
    prefix = %NetAddr.Prefix{address: <<0xfe,0x80, 0::14 * 8>>, length: 64}

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

  fact "pretty-prints IPv4 prefix" do
    %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}
    |> NetAddr.prefix_to_ipv4_cidr
    |> "192.0.2.0/24"
  end

  fact "converts decimal number to hexadecimal string" do
    NetAddr.decimal_to_hexadecimal_string(0x1a) |> "1a"
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
    %NetAddr.Prefix{address: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>, length: 128}
    |> NetAddr.prefix_to_ipv6_prefix_string
    |> "fe80:0:0:0:0:0:0:c101/128"
  end

  fact "pretty-prints IPv6 prefix with compressed zeros" do
    %NetAddr.Prefix{address: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>, length: 128}
    |> NetAddr.prefix_to_ipv6_prefix_string
    |> NetAddr.compress_ipv6_string
    |> "fe80::c101/128"
  end

  fact "pretty-prints IPv6 prefix with compressed zeros for only largest group of zeros" do
    %NetAddr.Prefix{address: <<0xfe,0x80, 0::2 * 8, 0xc1, 0::10 * 8, 0x01>>, length: 128}
    |> NetAddr.prefix_to_ipv6_prefix_string
    |> NetAddr.compress_ipv6_string
    |> "fe80:0:c100::1/128"
  end

  fact "parses a hyphen-delimited MAC address" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    NetAddr.mac("01-23-45-67-89-AB") |> result
  end
  fact "parses a different hyphen-delimited MAC address" do
    result = %NetAddr.Prefix{
      address: <<0xc0, 0xff, 0x33, 0xc0, 0xff, 0x33>>,
      length: 48
    }

    assert NetAddr.mac("C0-FF-33-C0-FF-33") == result
  end
  fact "parses a colon-delimited MAC address" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    NetAddr.mac("01:23:45:67:89:AB") |> result
  end
  fact "parses a space-delimited MAC address" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    NetAddr.mac("01 23 45 67 89 AB") |> result
  end
  fact "parses a MAC address with lowercase letters" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    NetAddr.mac("01-23-45-67-89-ab") |> result
  end
  fact "parses a MAC address with single-digit parts" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    NetAddr.mac("1-23-45-67-89-ab") |> result
  end
  fact "parses a MAC address with no delimiting characters" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    assert NetAddr.mac("0123456789ab") == result
  end
  fact "parses a MAC address with extraneous characters" do
    result = %NetAddr.Prefix{
      address: <<0x01, 0x23, 0x45, 0x67, 0x89, 0xab>>,
      length: 48
    }

    assert NetAddr.mac("\"0123456789ab \"") == result
  end
  #fact "fails when parsing a MAC address with no delimiting characters and too few digits" do
  #  fn -> NetAddr.mac("123456789ab") end |> raises ArgumentError
  #end
  #fact "fails when parsing invalid MAC address" do
  #  fn -> NetAddr.mac("01-23-45-67-89-ag") end |> raises ArgumentError
  #end

  fact "determines that one prefix contains another" do
    prefix1 = %NetAddr.Prefix{address: <<192,0,2,0>>, length: 24}
    prefix2 = %NetAddr.Prefix{address: <<192,0,2,128>>, length: 25}

    assert prefix1 |> NetAddr.contains?(prefix2) == true
  end
end
