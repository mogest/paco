defmodule Paco.Parser.RepeatTest do
  use ExUnit.Case, async: true

  import Paco
  import Paco.Parser

  test "parse" do
    assert parse(repeat(lit("a"), 0), "aaa") == {:ok, []}
    assert parse(repeat(lit("a"), 1), "aaa") == {:ok, ["a"]}
    assert parse(repeat(lit("a"), 2), "aaa") == {:ok, ["a", "a"]}

    assert parse(repeat(lit("a"), {2, 3}), "aaa") == {:ok, ["a", "a", "a"]}

    assert parse(repeat(lit("a"), less_than: 2), "aaa") == {:ok, ["a"]}
    assert parse(repeat(lit("a"), more_than: 2), "aaa") == {:ok, ["a", "a", "a"]}
    assert parse(repeat(lit("a"), at_most: 2), "aaa") == {:ok, ["a", "a"]}
    assert parse(repeat(lit("a"), at_least: 2), "aaa") == {:ok, ["a", "a", "a"]}

    assert parse(repeat(lit("a")), "") == {:ok, []}
    assert parse(repeat(lit("a")), "a") == {:ok, ["a"]}
    assert parse(repeat(lit("a")), "aa") == {:ok, ["a", "a"]}
    assert parse(repeat(lit("a")), "aaa") == {:ok, ["a", "a", "a"]}
  end

  test "correctly advance the position position" do
    parser = repeat(lit("ab"))
    success = parse(parser, "abab", format: :raw)
    assert success.from == {0, 1, 1}
    assert success.to == {3, 1, 4}
    assert success.at == {4, 1, 5}
    assert success.tail == ""
  end

  test "repeat and skip" do
    assert parse(repeat(skip(lit("a"))), "aaa") == {:ok, []}
    assert parse(repeat(one_of([skip(lit("a")), lit("b")])), "abab") == {:ok, ["b", "b"]}
    assert parse(repeat(one_of([skip(lit("a")), lit("b")])), "ababa") == {:ok, ["b", "b"]}
  end

  test "boxing" do
    assert parse(repeat("a"), "aaa") == {:ok, ["a", "a", "a"]}
    assert parse(repeat({"a"}), "aaa") == {:ok, [{"a"}, {"a"}, {"a"}]}
  end

  test "fail to parse because it fails to match an exact number of times" do
    assert parse(repeat(lit("a"), 2), "ab") == {:error,
      ~s|expected "a" at 1:2 but got "b"|
    }
    assert parse(repeat(lit("a"), 2), "a") == {:error,
      ~s|expected "a" at 1:2 but got the end of input|
    }
  end

  test "fail to parse because it fails to match a mininum number of times" do
    assert parse(repeat(lit("a"), at_least: 2), "ab") == {:error,
      ~s|expected "a" at 1:2 but got "b"|
    }
    assert parse(repeat(lit("a"), at_least: 2), "a") == {:error,
      ~s|expected "a" at 1:2 but got the end of input|
    }
  end

  test "failure with description" do
    parser = repeat(lit("a"), 2) |> as("REPEAT")
    assert parse(parser, "ab") == {:error,
      ~s|expected "a" (REPEAT) at 1:2 but got "b"|
    }
  end

  test "sugar combinators failure" do
    assert parse(lit("a") |> exactly(2), "ab") == {:error,
      ~s|expected "a" at 1:2 but got "b"|
    }
    assert parse(lit("a") |> at_least(2), "ab") == {:error,
      ~s|expected "a" at 1:2 but got "b"|
    }
    assert parse(lit("a") |> one_or_more, "bb") == {:error,
      ~s|expected "a" at 1:1 but got "b"|
    }
    assert parse(lit("a") |> exactly(5), "aaabbb") == {:error,
      ~s|expected "a" at 1:4 but got "b"|
    }
  end

  test "cut creates fatal failures" do
    without_cut = repeat(sequence_of([lit("a"), lit("b")]))
    assert parse(without_cut, "ab") == {:ok, [["a", "b"]]}
    assert parse(without_cut, "aba") == {:ok, [["a", "b"]]}

    with_cut = repeat(sequence_of([lit("a"), cut, lit("b")]))
    assert parse(with_cut, "ab") == {:ok, [["a", "b"]]}
    assert parse(with_cut, "aba") == {:error,
      ~s|expected "b" at 1:4 but got the end of input|
    }
  end

  test "consumes input on success" do
    parser = repeat(lit("a"))
    success = parser.parse.(Paco.State.from("aab"), parser)
    assert success.from == {0, 1, 1}
    assert success.to == {1, 1, 2}
    assert success.at == {2, 1, 3}
    assert success.tail == "b"
  end

  test "doesn't consume input on empty success" do
    parser = repeat(lit("a"))
    success = parser.parse.(Paco.State.from("bbb"), parser)
    assert success.from == {0, 1, 1}
    assert success.to == {0, 1, 1}
    assert success.at == {0, 1, 1}
    assert success.tail == "bbb"
  end

  test "doesn't consume input on failure" do
    parser = repeat(lit("a"), at_least: 1)
    failure = parser.parse.(Paco.State.from("bbb"), parser)
    assert failure.at == {0, 1, 1}
    assert failure.tail == "bbb"
  end
end
