defmodule Gramex.Case do
  use ExUnit.CaseTemplate

  alias Gramex.Testing.Sessions.Registry

  using do
    quote do
      import Gramex.Testing.BotCase.SessionHelpers
      import Mimic
    end
  end

  setup do
    start_supervised!(Registry)
    :ok
  end
end
