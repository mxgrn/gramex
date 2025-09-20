defmodule Gramex.Testing.BotCase do
  use ExUnit.CaseTemplate

  alias __MODULE__.Registry

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Gramex.Testing.Session
    end
  end

  setup do
    start_supervised!(Registry)
    :ok
  end
end
