netaddr-elixir
=========

### Parsing:

```
iex> NetAddr.ipv4_cidr "192.0.2.1/24"
%NetAddr.Prefix{length: 24, network: <<192, 0, 2, 0>>}

iex> NetAddr.ipv4 "192.0.2.1"
%NetAddr.Prefix{length: 32, network: <<192, 0, 2, 1>>}

iex> NetAddr.ipv6_prefix "fe80:0:c100::c401/64"
%NetAddr.Prefix{length: 64, network: <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>}

iex> NetAddr.ipv6 "fe80:0:c100::c401"
%NetAddr.Prefix{length: 128, network: <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>}
```

### Pretty-printing:

```
iex> NetAddr.ipv4_cidr("192.0.2.1/24") |> NetAddr.prefix_to_ipv4_cidr                                          
"192.0.2.1/24"

iex> NetAddr.ipv6("fe80:0:c100::c401") |> NetAddr.prefix_to_ipv6_prefix_string |> NetAddr.compress_ipv6_string
"fe80:0:c100::c401/128"
```

### Conversion:

```
iex> NetAddr.ipv4("192.0.2.1/24") |> NetAddr.Prefix.length(22)
%NetAddr.Prefix{address: <<192, 0, 0, 0>>, length: 22}


iex> NetAddr.aton <<192,0,2,1>>
3221225985

iex> NetAddr.ipv4_ntoa 3221225985
<<192, 0, 2, 1>>


iex> NetAddr.aton <<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>
338288524986991696549538495105230488577

iex> NetAddr.ipv6_ntoa 338288524986991696549538495105230488577
<<254, 128, 0, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 1>>


iex> NetAddr.prefix_length_to_mask(30, 32)
<<255, 255, 255, 252>>

iex> NetAddr.prefix_length_to_mask(64, 128)
<<255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0>>
```

### Arbitrary length addresses:

```
iex> NetAddr.prefix(<<1, 2, 3, 4, 5, 6>>, 40, 6) 
%NetAddr.Prefix{length: 40, network: <<1, 2, 3, 4, 5, 0>>}

iex> NetAddr.aton(<<1,2,3,4,5,6>>)
1108152157446

iex> NetAddr.ntoa 1108152157446, 48
<<1, 2, 3, 4, 5, 6>>

iex> NetAddr.prefix_length_to_mask(37, 48) 
<<255, 255, 255, 255, 248, 0>>
```
