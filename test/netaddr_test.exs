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

    NetAddr.length_to_mask(18, 32) |> mask
  end

  fact "converts a mask to a length" do
    NetAddr.mask_to_length(<<255,255,192,0>>) |> 18
  end

  fact "parses an IPv6 address" do
    prefix = %NetAddr.Prefix{network: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>, length: 128}

    NetAddr.ipv6("fe80:0:0:0:0:0:0:c101") |> prefix
  end

  fact "parses IPv6 prefix" do
    prefix = %NetAddr.Prefix{network: <<0xfe,0x80, 0::14 * 8>>, length: 64}

    NetAddr.ipv6_prefix("fe80::/64") |> prefix
  end

  fact "splits decimal into bytes" do
    NetAddr.split_number_into_bytes(256, 2) |> [1, 0]
  end

  fact "pads with zeros when splitting decimal into more bytes than are required to represent it" do
    NetAddr.split_number_into_bytes(256, 4) |> [0, 0, 1, 0]
  end

  fact "truncates most significant bits when splitting decimal into fewer bytes than are required to represent it" do
    NetAddr.split_number_into_bytes(256, 1) |> [0]
  end

  fact "combines bytes into a decimal" do
    result = 16843009
    <<1,1,1,1>> = <<result::32>>

    NetAddr.combine_bytes_into_number([1,1,1,1]) |> result
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

  #fact "pretty-prints IPv6 prefix" do
  #  %NetAddr.Prefix{network: <<0xfe,0x80, 0::12 * 8, 0xc1, 0x01>>, length: 128}
  #  |> NetAddr.prefix_to_ipv6_string
  #  |> "fe80:0:0:0:0:0:0:c101/128"
  #end
end
