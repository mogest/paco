defmodule Paco.Parser.SurroundedByTest do
  use ExUnit.Case, async: true

  import Paco
  import Paco.Parser

  alias Paco.Test.Helper

  test "success" do
    assert parse(surrounded_by(lit("a"), lit("["), lit("]")), "[a]") == {:ok, "a"}
    assert parse(surrounded_by(lit("a"), lit("*")), "*a*") == {:ok, "a"}
  end

  test "describe" do
    assert describe(surrounded_by(lit("a"), lit("["), lit("]"))) ==
      "surrounded_by#4(lit#1, lit#2, lit#3)"
  end

  test "failure because of surrounded parser" do
    assert parse(surrounded_by(lit("a"), lit("["), lit("]")), "[b]") == {:error,
      """
      Failed to match surrounded_by#4(lit#1, lit#2, lit#3) at 1:1, because it failed to match lit#1("a") at 1:2
      """
    }
  end

  test "failure because of left parser" do
    assert parse(surrounded_by(lit("a"), lit("["), lit("]")), "*a]") == {:error,
      """
      Failed to match surrounded_by#4(lit#1, lit#2, lit#3) at 1:1, because it failed to match lit#2("[") at 1:1
      """
    }
  end

  test "failure because of right parser" do
    assert parse(surrounded_by(lit("a"), lit("["), lit("]")), "[a*") == {:error,
      """
      Failed to match surrounded_by#4(lit#1, lit#2, lit#3) at 1:1, because it failed to match lit#3("]") at 1:3
      """
    }
  end

  test "notify events on success" do
    parser = lit("a") |> surrounded_by(lit("["), lit("]"))
    assert Helper.events_notified_by(parser, "[a]") == [
      {:loaded, "[a]"},
      {:started, "surrounded_by#4(lit#1, lit#2, lit#3)"},
      {:started, "sequence_of#7([skip#5, lit#1, skip#6])"},
      {:started, "skip#5(lit#2)"},
      {:started, ~s|lit#2("[")|},
      {:matched, {0, 1, 1}, {0, 1, 1}, {1, 1, 2}},
      {:matched, {0, 1, 1}, {0, 1, 1}, {1, 1, 2}},
      {:started, ~s|lit#1("a")|},
      {:matched, {1, 1, 2}, {1, 1, 2}, {2, 1, 3}},
      {:started, "skip#6(lit#3)"},
      {:started, ~s|lit#3("]")|},
      {:matched, {2, 1, 3}, {2, 1, 3}, {3, 1, 4}},
      {:matched, {2, 1, 3}, {2, 1, 3}, {3, 1, 4}},
      {:matched, {0, 1, 1}, {2, 1, 3}, {3, 1, 4}},
      {:matched, {0, 1, 1}, {2, 1, 3}, {3, 1, 4}}]
  end

  test "notify events on failure" do
    parser = lit("a") |> surrounded_by(lit("["), lit("]"))
    assert Helper.events_notified_by(parser, "[b]") == [
      {:loaded, "[b]"},
      {:started, "surrounded_by#4(lit#1, lit#2, lit#3)"},
      {:started, "sequence_of#7([skip#5, lit#1, skip#6])"},
      {:started, "skip#5(lit#2)"},
      {:started, ~s|lit#2("[")|},
      {:matched, {0, 1, 1}, {0, 1, 1}, {1, 1, 2}},
      {:matched, {0, 1, 1}, {0, 1, 1}, {1, 1, 2}},
      {:started, ~s|lit#1("a")|},
      {:failed, {1, 1, 2}},
      {:failed, {0, 1, 1}},
      {:failed, {0, 1, 1}}]
  end
end
