defmodule NetAddr.Utility do
  defp range(ctxt, range) do
    ctxt
    |> Enum.reverse
    |> Enum.concat([range])
    |> Enum.join
  end

  defp _range_to_regex([], [], _, [], acc) do
    str =
      acc
      |> Enum.reverse
      |> Enum.join("|")

    if length(acc) > 1 do
      str
      |> String.replace_prefix("", "(")
      |> String.replace_suffix("", ")")
    else
      str
    end
  end

  defp _range_to_regex([], [], _, [{a, b, ctxt}|t], acc),
    do: _range_to_regex(a, b, ctxt, t, acc)

  defp _range_to_regex(a, b, ctxt, stack, acc)
      when length(a) < length(b)
  do
    count  = length(b) - 1
    zeros  = List.duplicate(0, count)
    nines  = List.duplicate(9, count)
    next_b = nines
    new_a  = [1|zeros]

    next_stack = [{new_a, b, ctxt}|stack]

    _range_to_regex(a, next_b, ctxt, next_stack, acc)
  end

  defp _range_to_regex([h], [h], ctxt, stack, acc) do
    range = range(ctxt, "#{h}")

    _range_to_regex([], [], ctxt, stack, [range|acc])
  end

  defp _range_to_regex([h|t1], [h|t2], ctxt, stack, acc),
    do: _range_to_regex(t1, t2, [h|ctxt], stack, acc)

  defp _range_to_regex([h1], [h2], ctxt, stack, acc) do
    range = range(ctxt, "[#{h1}-#{h2}]")

    _range_to_regex([], [], ctxt, stack, [range|acc])
  end

  defp _range_to_regex(
    [h1|t1] = a,
    [h2|t2] = b,
    ctxt,
    stack,
    acc
  ) do
    count = length(t1)
    zeros = List.duplicate(0, count)
    nines = List.duplicate(9, count)

    cond do
      t1 == zeros and t2 == nines ->
        free_range =
          "[0-9]"
          |> List.duplicate(count)
          |> Enum.join

        range =
          if h1 == 0 and h2 == 9,
            do: range(ctxt, "[0-9]#{free_range}"),
          else: range(ctxt, "[#{h1}-#{h2}]#{free_range}")

        _range_to_regex([], [], ctxt, stack, [range|acc])

      t2 == nines ->
        next_b = [h1    |nines]
        new_a  = [h1 + 1|zeros]

        next_stack = [{new_a, b, ctxt}|stack]

        _range_to_regex(a, next_b, ctxt, next_stack, acc)

      true ->
        next_b = [h2 - 1|nines]
        new_a  = [h2    |zeros]

        next_stack = [{new_a, b, ctxt}|stack]

        _range_to_regex(a, next_b, ctxt, next_stack, acc)
    end
  end

  def range_to_regex(a..a),
    do: "#{a}"

  def range_to_regex(a..b) when a > b,
    do: range_to_regex(b..a)

  def range_to_regex(a..b) when a < b do
    a_digits = Integer.digits(a)
    b_digits = Integer.digits(b)

    _range_to_regex(a_digits, b_digits, [], [], [])
  end
end
