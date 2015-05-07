defmodule Paco.Input do
  @type position :: {non_neg_integer, non_neg_integer, non_neg_integer}
  @type t :: %__MODULE__{at: non_neg_integer,
                         text: String.t,
                         target: pid | nil,
                         stream: pid | nil}

  defstruct at: {0, 1, 1}, text: "", target: nil, stream: nil

  def from(s, opts \\ []) when is_binary(s) do
    %__MODULE__{at: {0, 1, 1},
                text: s,
                target: Keyword.get(opts, :target, nil),
                stream: Keyword.get(opts, :stream, nil)}
  end
end
