defmodule Paco.Parser.Label.Test do
  use ExUnit.Case

  import Paco
  import Paco.Parser

  test "label the name of a parser" do
    assert "an a" == label(string("a"), "an a").name
  end

  test "label shows up in the failure message" do
    labeled = label(string("a"), "an a")
    {:error, failure} = parse(labeled, "b")
    assert Paco.Failure.format(failure) ==
      """
      Failed to match an a at line: 1, column: 1
      """
  end
end
