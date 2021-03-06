defmodule Paco.String do
  import String
  alias Paco.State

  @typep limit :: exactly::non_neg_integer | {at_least::non_neg_integer, at_most::non_neg_integer}


  @spec consume(text::String.t, expected::String.t, at::State.position)
    :: {tail::String.t, consumed::String.t, to::State.position, at::State.position}
     | {:not_expected, tail::String.t, consumed::String.t, to::State.position, at::State.position}
     | {:not_enough, tail::String.t, consumed::String.t, to::State.position, at::State.position}

  def consume(text, expected, at), do: consume(text, "", expected, at, at)

  defp consume(text, consumed, "", to, at), do: {text, consumed, to, at}
  defp consume("", consumed, _, to, at), do: {:not_enough, "", consumed, to, at}
  defp consume(text, consumed, expected, to, at) do
    {h1, t1} = next_grapheme(text)
    {h2, t2} = next_grapheme(expected)
    case {h1, h2} do
      {h, h} -> consume(t1, consumed <> h, t2, at, position_after(at, h))
      _      -> {:not_expected, text, consumed, to, at}
    end
  end


  @spec consume(text::String.t, limits::limit, at::State.position)
    :: {tail::String.t, consumed::String.t, to::State.position, at::State.position}
     | {:not_enough, tail::String.t, consumed::String.t, to::State.position, at::State.position}

  def consume_any(text, {at_least, at_most}, at),
    do: consume_any(text, "", {at_least, at_most, 0}, at, at)
  def consume_any(text, n, at),
    do: consume_any(text, "", {n, n, 0}, at, at)

  defp consume_any(text, consumed, {at_least, at_most, n}, to, at) do
    case next_grapheme(text) do
      {h, tail} when n+1 == at_most  ->
        {tail, consumed <> h, at, position_after(at, h)}
      {h, tail} ->
        consume_any(tail, consumed <> h, {at_least, at_most, n+1}, at, position_after(at, h))
      nil when n < at_least ->
        {:not_enough, text, consumed, to, at}
      nil ->
        {text, consumed, to, at}
    end
  end


  @spec consume_while(text::String.t, what, limits::limit, at::State.position)
    :: {tail::String.t, consumed::String.t, to::State.position, at::State.position}
     | {:not_enough, tail::String.t, consumed::String.t, to::State.position, at::State.position}
    when what: String.t | [String.t] | (String.t -> boolean)

  def consume_while(text, what, {at_least, at_most}, at),
      do: consume_while(text, "", what, {at_least, at_most, 0}, at, at)
  def consume_while(text, what, n, at),
      do: consume_while(text, "", what, {n, n, 0}, at, at)

  def consume_while(text, what, at),
      do: consume_while(text, "", what, {0, :infinity, 0}, at, at)

  defp consume_while(text, consumed, what, limits, at, at) when is_list(what) do
    f = fn(h) -> Enum.any?(what, &(&1 == h)) end
    consume_while(text, consumed, f, limits, at, at)
  end

  defp consume_while(text, consumed, what, limits, at, at) when is_binary(what) do
    expected = Stream.unfold(what, &next_grapheme/1) |> Enum.to_list
    f = fn(h) -> Enum.any?(expected, &(&1 == h)) end
    consume_while(text, consumed, f, limits, at, at)
  end

  defp consume_while(text, consumed, f, {at_least, at_most, n}, to, at) when is_function(f) do
    case next_grapheme(text) do
      {h, tail} ->
        case f.(h) do
          true when n+1 == at_most ->
            {tail, consumed <> h, at, position_after(at, h)}
          true ->
            consume_while(tail, consumed <> h, f, {at_least, at_most, n+1}, at, position_after(at, h))
          false when n < at_least ->
            {:not_enough, text, consumed, to, at}
          false ->
            {text, consumed, to, at}
        end
      nil when n < at_least ->
        {:not_enough, text, consumed, to, at}
      nil ->
        {text, consumed, to, at}
    end
  end


  @spec consume_until(text::String.t, what, at::State.position, opts::Keyword.t)
    :: {tail::String.t, consumed::String.t, to::State.position, at::State.position}
     | {:not_enough, tail::String.t, consumed::String.t, to::State.position, at::State.position}
    when what: {boundary::String.t, escape::String.t}

  def consume_until(text, boundary, at, opts \\ [])

  def consume_until(text, boundary, at, opts) when is_binary(boundary),
    do: consume_until(text, "", [boundary], at, at, opts)
  def consume_until(text, {boundary, escape}, at, opts) when is_binary(boundary) and is_binary(escape),
    do: consume_until(text, "", [{boundary, escape}], at, at, opts)
  def consume_until(text, boundaries, at, opts) when is_list(boundaries),
    do: consume_until(text, "", boundaries, at, at, opts)

  defp consume_until(text, consumed, boundaries, to, at, opts) do
    opts = {Keyword.get(opts, :keep_escape, false), Keyword.get(opts, :eof, false)}
    boundaries = Enum.concat(boundaries, boundaries_escaped_without_escape(boundaries))
    consume_until_boundaries(text, consumed, boundaries, boundaries, to, at, opts)
  end

  defp consume_until_boundaries(text, consumed, [], boundaries, _to, at, opts) do
    {h, tail} = next_grapheme(text)
    consume_until_boundaries(tail, consumed <> h, boundaries, boundaries, at, position_after(at, h), opts)
  end
  defp consume_until_boundaries(text, consumed, [{boundary, escape}|rest_of_boundaries], boundaries, to, at, {keep_escape, _} = opts) do
    case consume(text, "", escape <> boundary, to, at) do
      {tail, escaped_boundary, to, at} when keep_escape ->
        consume_until_boundaries(tail, consumed <> escaped_boundary, boundaries, boundaries, to, at, opts)
      {tail, _, to, at} ->
        consume_until_boundaries(tail, consumed <> boundary, boundaries, boundaries, to, at, opts)
      {:not_expected, _, _, _, _} ->
        consume_until_boundaries(text, consumed, rest_of_boundaries, boundaries, to, at, opts)
      {:not_enough, _, _, _, _} ->
        consume_until_boundaries(text, consumed, rest_of_boundaries, boundaries, to, at, opts)
    end
  end
  defp consume_until_boundaries(text, consumed, [boundary|rest_of_boundaries], boundaries, to, at, {_, eof_is_boundary} = opts) do
    case consume(text, "", boundary, to, at) do
      {_, _, _, _} ->
        {text, consumed, to, at}
      {:not_expected, _, _, _, _} ->
        consume_until_boundaries(text, consumed, rest_of_boundaries, boundaries, to, at, opts)
      {:not_enough, _, _, _, _} when eof_is_boundary ->
        {text, consumed, to, at}
      {:not_enough, _, _, _, _} ->
        {:not_enough, text, consumed, to, at}
    end
  end

  defp boundaries_escaped_without_escape(boundaries) do
    Enum.reduce(boundaries, [],
                fn({boundary, _}, acc) -> [boundary|acc]
                  (_, acc) -> acc
                end)
    |> Enum.reverse
  end


  @spec seek(text::String.t, n::non_neg_integer, at::State.position)
    :: {tail::String.t, seeked::String.t, to::State.position, at::State.position}
     | {:not_enough, tail::String.t, seeked::String.t, to::State.position, at::State.position}

  def seek(text, n, at), do: seek(text, "", n, at, at)

  defp seek(text, seeked, 0, to, at), do: {text, seeked, to, at}
  defp seek(text, seeked, n, to, at) do
    case next_grapheme(text) do
      {h, tail} ->
        seek(tail, seeked <> h, n-1, at, position_after(at, h))
      nil ->
        {:not_enough, text, seeked, to, at}
    end
  end


  defp position_after({n, l, _}, "\n"), do: {n + 1, l + 1, 1}
  defp position_after({n, l, _}, "\v"), do: {n + 1, l + 1, 1}
  defp position_after({n, l, _}, "\f"), do: {n + 1, l + 1, 1}
  defp position_after({n, l, _}, "\r\n"), do: {n + 1, l + 1, 1}
  defp position_after({n, l, _}, "\r"), do: {n + 1, l + 1, 1}
  defp position_after({n, l, c}, _), do: {n + 1, l, c + 1}



  @spec line_at(text::String.t, at::non_neg_integer) :: String.t

  def line_at(text, at) do
    case String.at(text, at) do
      nil ->
        case String.length(text) do
          0 -> ""
          n -> line_at(text, n - 1)
        end
      grapheme ->
        if (Paco.ASCII.newline?(grapheme)) do
          collect_line_at(text, at - 1, &(&1 - 1))
          |> Enum.reverse
          |> Enum.join
        else
          collect_line_at(text, at - 1, &(&1 - 1))
          |> Enum.reverse
          |> Enum.concat([grapheme])
          |> Enum.concat(collect_line_at(text, at + 1, &(&1 + 1)))
          |> Enum.join
        end
    end
  end

  defp collect_line_at(text, at, next) do
    Stream.unfold(at, &collect_line_at_(text, &1, next)) |> Enum.to_list
  end

  defp collect_line_at_(_text, at, _next) when at < 0, do: nil
  defp collect_line_at_(text, at, next) do
    case String.at(text, at) do
      nil ->
        nil
      in_line ->
        if Paco.ASCII.newline?(in_line) do
          nil
        else
          {in_line, next.(at)}
        end
    end
  end
end
