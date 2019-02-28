netaddr-elixir
=========

[![Build Status](https://gitlab.com/jonnystorm/netaddr-elixir/badges/master/pipeline.svg)](https://gitlab.com/jonnystorm/netaddr-elixir/commits/master)

General functions for network address parsing and manipulation, with support for addresses of arbitrary size.

See the [API documentation](http://jonnystorm.gitlab.io/netaddr-elixir).

### Parsing:

```elixir
iex> NetAddr.ip "192.0.2.1/24"
%NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 24}

iex> NetAddr.ip "192.0.2.1"
%NetAddr.IPv4{address: <<192, 0, 2, 1>>, length: 32}


iex> NetAddr.ip "fe80:0:c100::c401/64"
%NetAddr.IPv6{address: <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>, length: 64}

iex> NetAddr.ip "fe80:0:c100::c401"
%NetAddr.IPv6{address: <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>, length: 128}
```

### Pretty-printing:

```elixir
iex> "#{NetAddr.ip("192.0.2.1/24")}"
"192.0.2.1/24"

iex> "#{NetAddr.ip("fe80:0:c100::c401")}"
"fe80:0:c100::c401/128"
```

### Conversion:

```elixir
iex> NetAddr.network NetAddr.ipv4_cidr("192.0.2.1/24")
"192.0.2.0"

iex> NetAddr.ip("192.0.2.1/24") |> NetAddr.address_length(22) |> NetAddr.network
"192.0.0.0"


iex> NetAddr.aton <<192,0,2,1>>
3221225985

iex> NetAddr.ntoa 3221225985, 4
<<192, 0, 2, 1>>


iex> NetAddr.aton <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>
338288524986991696549538495105230488577

iex> NetAddr.ntoa 338288524986991696549538495105230488577, 16
<<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>


iex> NetAddr.length_to_mask(30, 4)
<<255, 255, 255, 252>>

iex> NetAddr.length_to_mask(64, 16)
<<255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0>>


iex> NetAddr.ip("198.51.100.0/24") |> NetAddr.netaddr_to_range
3325256704..3325256959

iex> NetAddr.range_to_netaddr 3325256704..3325256959, 4
%NetAddr.IPv4{address: <<198, 51, 100, 0>>, length: 24}
```

### Arbitrary length addresses:

```elixir
iex> NetAddr.netaddr(<<1, 2, 3, 4, 5, 6>>)
%NetAddr.MAC_48{address: <<1, 2, 3, 4, 5, 6>>, length: 48}

iex> NetAddr.netaddr(<<1, 2, 3, 4, 5>>, 48, 6)
%NetAddr.Generic{address: <<0, 1, 2, 3, 4, 5>>, length: 48}

iex> NetAddr.netaddr(<<1, 2, 3, 4, 5>>)
%NetAddr.Generic{address: <<1, 2, 3, 4, 5>>, length: 40}

iex> "#{NetAddr.netaddr(<<1, 2, 3, 4, 5>>)}"
"0x0102030405/40"

iex> NetAddr.aton(<<1,2,3,4,5>>)
4328719365

iex> NetAddr.ntoa 4328719365, 5
<<1, 2, 3, 4, 5>>

iex> NetAddr.length_to_mask(37, 6)
<<255, 255, 255, 255, 248, 0>>
```
