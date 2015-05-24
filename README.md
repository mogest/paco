# Paco
[![Build Status](https://travis-ci.org/gabrielelana/paco.svg?branch=master)](https://travis-ci.org/gabrielelana/paco)

## Example
```elixir

defmodule Expression do
  use Paco

  parser expression do
    one_of([number, expression]) |> separated_by(",") |> surrounded_by("(", ")")
  end
end

Expression.parse("(7, (4, 5), (1, 2, 3), 6)") # => [7, [4, 5], [1, 2, 3], 6]
```
