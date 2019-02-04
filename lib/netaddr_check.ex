defmodule NetAddrCheck do
  @moduledoc false

  import NetAddr

  # Trigger success typing in NetAddr module
  #
  # What all did I miss?
  #
  def check do
    {:ok, netaddr1} = ip_2("192.0.2.0/24")

    netaddr2 = ip("198.51.100.1")

    ipv4_netaddr = netaddr = netaddr1

    _ = address_length(netaddr)
    _ = address(netaddr)
    _ = address_size(netaddr)
    _ = apply_mask(<<192,0,2,1>>, <<255,255,255,0>>)
    _ = aton(<<192,0,2,1>>)
    _ = broadcast(ipv4_netaddr)
    _ = contains?(netaddr1, netaddr2)
    _ = erl_ip_to_netaddr({192,0,2,1})
    _ = first_address(netaddr)
    _ = is_host_address(netaddr)
    _ = is_ip("test")
    _ = is_ipv4("test")
    _ = is_ipv6("test")
    _ = last_address(netaddr)
    _ = length_to_mask(23, 4)
    _ = mac_48_2("c0ff33-c0ff33")
    _ = mac_48("c0ff33-c0ff33")
    _ = mask_to_length_2("255.255.254.0")
    _ = mask_to_length("248.0.0.0")
    _ = netaddr_2(<<192,0,2,1>>)
    _ = netaddr(<<192,0,2,1>>)
    _ = netaddr_2(<<192,0,2,1>>, 23)
    _ = netaddr(<<192,0,2,1>>, 23)
    _ = netaddr_to_erl_ip(netaddr)
    _ = netaddr_to_list(netaddr)
    _ = netaddr_to_ptr(netaddr)
    _ = netaddr_to_range(netaddr)
    _ = netaddr_to_regex(ipv4_netaddr)
    _ = netaddr_to_string(netaddr)
    _ = network(netaddr)
    _ = ntoa(98279872, 4)
    _ = prefix(netaddr)
    _ = ptr_to_netaddr("1.2.0.192.in-addr.arpa")
    _ = range_to_netaddr(98279872..98279873, 4)
    _ = subnet_mask(ipv4_netaddr)
    _ = to_string(netaddr)
  end
end
