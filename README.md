netaddr-elixir
=========

```
iex> prefix = NetAddr.ipv4("255.255.254.0")
%NetAddr.Prefix{length: 32, network: <<255, 255, 254, 0>>}

iex> prefix |> NetAddr.Prefix.network |> NetAddr.mask_to_length
23

iex> prefix = NetAddr.ipv6_prefix("fe80::c401/64")
%NetAddr.Prefix{length: 128,
 network: <<254, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>}
```
