defmodule Gramex.Case do
  use ExUnit.CaseTemplate

  alias Gramex.Testing.BotCase.Registry

  using do
    quote do
      import Mimic
    end
  end

  setup do
    start_supervised!(Registry)
    :ok
  end
end
