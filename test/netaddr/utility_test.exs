# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

defmodule NetAddr.UtilityTest do
  use ExUnit.Case, async: true

  import NetAddr.Utility

  test "generates regex matching 1..65535" do
    range = 47..65535
    regex =
      range
      |> range_to_regex
      |> String.replace_prefix("", "\\b")
      |> String.replace_suffix("", "\\b")
      |> Regex.compile!

    assert Enum.all?(range, & "#{&1}" =~ regex)
    refute "46" =~ regex
    refute "65536" =~ regex
  end
end
