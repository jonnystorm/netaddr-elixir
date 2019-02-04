defmodule NetAddr.Utility do
  defp accrete_match(acc, ctxt, match, exp) do
    next_match =
      [ Enum.join(Enum.reverse(ctxt)),
        match
      | List.duplicate("[0-9]", exp)
      ]
      |> Enum.join

    Enum.join([acc, next_match], "|")
  end

  defp _range_to_regex([], [], _ctxt, acc) do
    acc
    |> String.replace_prefix("|", "(")
    |> String.replace_suffix("", ")")
  end

  defp _range_to_regex([h|t] = first, last, ctxt, acc)
      when length(first) < length(last)
  do
    next_acc =
      accrete_match(acc, ctxt, "[#{h}-9]", length(t))

    {next_first, next_ctxt} =
      case ctxt do
        []       -> {[1, 0|t], []}
        [c|rest] -> {[(c + 1), 0|t], rest}
      end

    _range_to_regex(next_first, last, next_ctxt, next_acc)
  end

  defp _range_to_regex([h|t1], [h|t2], ctxt, acc),
    do: _range_to_regex(t1, t2, [h|ctxt], acc)

  defp _range_to_regex([h1|t1], [h2|t2] = last, ctxt, acc)
      when length(t1) == length(t2)
  do
    digit_match =
      cond do
        length(t1) == 0 ->
          "[#{h1}-#{h2}]"

        true ->
          "[#{h1}-#{h2 - 1}]"
      end

    next_acc =
      accrete_match(acc, ctxt, digit_match, length(t1))

    _range_to_regex([h2|t1], last, ctxt, next_acc)
  end

  def range_to_regex(a..a),
    do: "#{a}"

  def range_to_regex(a..b)
      when a < b
  do
    [a_digits, b_digits] =
      Enum.map([a, b], &Integer.digits/1)

    [h|t] = Enum.reverse(a_digits)

    _range_to_regex([h], b_digits, t, "")
  end
end
