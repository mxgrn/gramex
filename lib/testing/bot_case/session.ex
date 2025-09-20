defmodule Gramex.Testing.BotCase.Session do
  defstruct [:user, updates: []]

  def new(user, updates \\ []) do
    %__MODULE__{user: user, updates: updates}
  end
end
