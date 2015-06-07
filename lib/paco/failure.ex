defmodule Paco.Failure do
  @type t :: %__MODULE__{at: Paco.State.position,
                         tail: String.t,
                         confidence: integer,
                         expected: String.t,
                         message: String.t | nil,
                         stack: [String.t],

                         tail: String.t, what: any, because: any}

  defexception at: {0, 0, 0}, tail: "", confidence: 0, expected: "", message: nil, stack: [],
               what: nil, because: nil

  def at(%Paco.State{at: at, text: text}, expected, opts \\ []) do
    %Paco.Failure{at: at, tail: text, expected: expected,
                  confidence: Keyword.get(:confidence, opts, 0),
                  message: Keyword.get(:message, opts, nil),
                  stack: Keyword.get(:stack, opts, [])}
  end

  def stack(%Paco.Parser{description: nil}), do: []
  def stack(%Paco.Parser{description: description}), do: [description]

  def stack(failure, %Paco.Parser{description: nil}), do: failure
  def stack(failure, %Paco.Parser{description: description}) do
    %Paco.Failure{failure|stack: [description|failure.stack]}
  end

  def message(%Paco.Failure{} = failure), do: format(failure, :flat)

  def format(%Paco.Failure{} = failure, :raw), do: failure
  def format(%Paco.Failure{} = failure, :tagged), do: {:error, format(failure, :flat)}
  def format(%Paco.Failure{} = failure, :flat) do
    [ "expected",
      format_expected(failure.expected),
      format_stack(failure.stack),
      format_position(failure.at),
      "but got",
      format_tail(failure.tail, failure.expected)
    ]
    |> Enum.reject(&(&1 === :empty))
    |> Enum.join(" ")
  end

  defp format_expected({:re, r}) do
    inspect(r)
  end
  defp format_expected({:until, p}) do
    ["something ended by", format_description({:until, p})]
    |> Enum.join(" ")
  end
  defp format_expected({:while, p, n, m}) do
    [format_limits({n, m}), "characters", format_description({:while, p})]
    |> Enum.join(" ")
  end
  defp format_expected({:any, n, m}) do
    [format_limits({n, m}), "characters"]
    |> Enum.join(" ")
  end
  defp format_expected(s) when is_binary(s) do
    quoted(s)
  end

  defp format_stack([]), do: :empty
  defp format_stack(descriptions) do
    ["(", descriptions |> Enum.reverse |> Enum.join(" < "), ")"]
    |> Enum.join("")
  end

  defp format_position({_, line, column}), do: "at #{line}:#{column}"

  defp format_tail("", _), do: "the end of input"
  defp format_tail(tail, s) when is_binary(s) do
    quoted(String.slice(tail, 0, String.length(s)))
  end
  defp format_tail(tail, _) do
    quoted(tail)
  end

  defp format_limits({n, n}), do: "exactly #{n}"
  defp format_limits({n, _}), do: "at least #{n}"

  defp format_description({:until, p}) when is_function(p) do
    "a character which satisfy #{format_function(p)}"
  end
  defp format_description({:until, {p, _}}) do
    quoted(p)
  end
  defp format_description({:until, p}) do
    quoted(p)
  end
  defp format_description({:while, p}) when is_binary(p) do
    "in alphabet #{quoted(p)}"
  end
  defp format_description({:while, p}) when is_function(p) do
    "which satisfy #{format_function(p)}"
  end

  defp format_function(f) do
    about_f = :erlang.fun_info(f)
    if Keyword.get(about_f, :type) == :external do
      Keyword.get(about_f, :name)
    else
      "fn/#{Keyword.get(about_f, :arity)}"
    end
  end

  defp quoted(text), do: ~s|"#{text}"|
end
