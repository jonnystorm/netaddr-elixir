# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

defmodule NetAddr.UtilityTest do
  use ExUnit.Case, async: true

  use NetAddr

  import NetAddr.Utility

  defp make_range_re(range) do
    range
    |> range_to_regex
    |> String.replace_prefix("", "\\b")
    |> String.replace_suffix("", "\\b")
    |> Regex.compile!
  end

  test "generates regex matching 1..65535" do
    range = 47..65535
    regex = make_range_re(range)

    assert Enum.all?(range, & "#{&1}" =~ regex)
    refute ("46" =~ regex)
    refute ("65536" =~ regex)
  end

  test "generates regex matching 16..31" do
    range = 16..31
    regex = make_range_re(range)

    assert Enum.all?(range, & "#{&1}" =~ regex)
    refute ("15" =~ regex)
    refute ("32" =~ regex)
  end

  test "generates regex matching 19..20" do
    range = 19..20
    regex = make_range_re(range)

    assert Enum.all?(range, & "#{&1}" =~ regex)
    refute ("18" =~ regex)
    refute ("21" =~ regex)
  end

  test "generates regex matching 18..19" do
    range = 18..19
    regex = make_range_re(range)

    assert Enum.all?(range, & "#{&1}" =~ regex)
    refute ("17" =~ regex)
    refute ("20" =~ regex)
  end

  test "generates regexes for reserved ranges" do
    reserved =
      ~p(0.0.0.0/8
         10.0.0.0/8
         100.64.0.0/10
         127.0.0.0/8
         169.254.0.0/16
         172.16.0.0/12
         192.0.0.0/24
         192.0.2.0/24
         192.88.99.0/24
         192.168.0.0/16
         198.18.0.0/15
         198.51.100.0/24
         203.0.113.0/24
         224.0.0.0/4
         240.0.0.0/4
         255.255.255.255/32
      )

    assert Enum.map(reserved, &NetAddr.netaddr_to_regex/1) != nil
  end
end
