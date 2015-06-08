defmodule Paco.Parser.BindTest do
  use ExUnit.Case, async: true

  import Paco
  import Paco.Parser

  test "bind to a function" do
    parser = bind(lit("a"), fn(_) -> "b" end)
    assert parse(parser, "a") == {:ok, "b"}
  end

  test "bind to a function/2" do
    parser = bind(lit("a"), fn(_, %Paco.Success{result: r}) -> r end)
    assert parse(parser, "a") == {:ok, "a"}
  end

  test "bind to a function/3" do
    parser = bind(lit("a"), fn(_, _, %Paco.State{at: at}) -> at end)
    assert parse(parser, "a") == {:ok, {1, 1, 2}}
  end

  test "bind can terminate with a failure" do
    parser = lit("a") |> bind(fn(_, _, state) ->
                                Paco.Failure.at(state, message: "bind gone wrong")
                              end)

    assert parse(parser, "a") == {:error, ~s|bind gone wrong|}
  end

  test "bind can terminate with a success" do
    parser = lit("a") |> bind(fn(_, success, _) ->
                                success
                              end)

    assert parse(parser, "a") == {:ok, "a"}
  end

  test "bind to a block" do
    parser = one_of([lit("a"), lit("b")])
             |> bind do
                 {"a", _, _} -> 1
                 {"b", _, _} -> 2
                end

    assert parse(parser, "a") == {:ok, 1}
    assert parse(parser, "b") == {:ok, 2}
  end

  test "bind to a block using the state" do
    parser = one_of([lit("a"), lit("bb")])
             |> bind do
                  {_, _, %Paco.State{at: at}} -> at
                end

    assert parse(parser, "a") == {:ok, {1, 1, 2}}
    assert parse(parser, "bb") == {:ok, {2, 1, 3}}
  end

  test "bind to an inline block" do
    parser = one_of([lit("a"), lit("b")])
             |> (bind do: ({"a",_,_} -> 1; {"b",_,_} -> 2))

    assert parse(parser, "a") == {:ok, 1}
    assert parse(parser, "b") == {:ok, 2}
  end

  test "boxing" do
    parser = bind("a", &String.duplicate(&1, 2))
    assert parse(parser, "a") == {:ok, "aa"}
  end

  test "fails if bind function raise an exception" do
    parser = bind(lit("a"), fn _  -> raise "boom!" end)
    assert parse(parser, "a") == {:error,
      ~s|exception: boom! at 1:1|
    }
  end

  test "failure with description" do
    parser = bind(lit("a"), fn _  -> raise "boom!" end) |> as ("BIND")
    assert parse(parser, "a") == {:error,
      ~s|exception: boom! (BIND) at 1:1|
    }
  end

  test "doesn't call bind function on failure" do
    parser = bind(lit("a"), fn(r) -> Process.put(:called, true); r end)
    parse(parser, "b")

    assert Process.get(:called, false) == false
  end
end
