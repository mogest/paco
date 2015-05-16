defmodule Paco.Parser.LiteralTest do
  use ExUnit.Case, async: true

  import Paco
  import Paco.Parser

  alias Paco.Test.Helper

  test "parse lit" do
    assert parse(lit("aaa"), "aaa") == {:ok, "aaa"}
  end

  test "parse multibyte lit" do
    assert parse(lit("あいうえお"), "あいうえお") == {:ok, "あいうえお"}
  end

  test "parse empty lit" do
    assert parse(lit(""), "") == {:ok, ""}
  end

  test "describe" do
    assert describe(lit("a")) == ~s|lit#1("a")|
    assert describe(lit("\n")) == ~S|lit#2("\n")|
  end

  test "skipped parsers should be removed from result" do
    assert parse(skip(lit("a")), "a") == {:ok, []}
  end

  test "fail to parse a lit" do
    assert parse(lit("aaa"), "bbb") == {:error,
      """
      Failed to match lit#1("aaa") at 1:1
      """
    }
  end

  test "skip doesn't influece failures" do
    assert parse(skip(lit("aaa")), "bbb") == {:error,
      """
      Failed to match lit#1("aaa") at 1:1
      """
    }
  end

  test "fail to parse empty lit" do
    assert parse(lit("aaa"), "") == {:error,
      """
      Failed to match lit#1("aaa") at 1:1
      """
    }
  end

  test "notify events on success" do
    assert Helper.events_notified_by(lit("aaa"), "aaa") == [
      {:loaded, "aaa"},
      {:started, ~s|lit#1("aaa")|},
      {:matched, {0, 1, 1}, {2, 1, 3}, {3, 1, 4}},
    ]
  end

  test "notify events on failure" do
    assert Helper.events_notified_by(lit("bbb"), "aaa") == [
      {:loaded, "aaa"},
      {:started, ~s|lit#1("bbb")|},
      {:failed, {0, 1, 1}},
    ]
  end

  test "increment indexes for a match" do
    parser = lit("aaa")
    success = parser.parse.(Paco.State.from("aaa"), parser)
    assert success.from == {0, 1, 1}
    assert success.to == {2, 1, 3}
    assert success.at == {3, 1, 4}
    assert success.tail == ""
  end

  test "increment indexes for a match with newlines" do
    parser = lit("a\na\na\n")
    success = parser.parse.(Paco.State.from("a\na\na\nbbb"), parser)
    assert success.from == {0, 1, 1}
    assert success.to == {5, 3, 2}
    assert success.at == {6, 4, 1}
    assert success.tail == "bbb"
  end

  test "increment indexes for a single character match" do
    parser = lit("a")
    success = parser.parse.(Paco.State.from("aaa"), parser)
    assert success.from == {0, 1, 1}
    assert success.to == {0, 1, 1}
    assert success.at == {1, 1, 2}
    assert success.tail == "aa"
  end

  test "increment indexes for an empty match" do
    parser = lit("")
    success = parser.parse.(Paco.State.from("aaa"), parser)
    assert success.from == {0, 1, 1}
    assert success.to == {0, 1, 1}
    assert success.at == {0, 1, 1}
    assert success.tail == "aaa"
  end
end