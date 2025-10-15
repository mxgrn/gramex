defmodule Gramex.Testing.Sessions.Chat do
  defstruct [:id, :type, :title, :username, :first_name, :last_name]

  def new(attrs \\ []) when is_list(attrs) do
    attrs =
      %{
        id: :rand.uniform(1_000_000_000) * if(:rand.uniform() > 0.5, do: 1, else: -1),
        type: "group",
        title: "Some Chat",
        username: nil,
        first_name: nil,
        last_name: nil
      }
      |> Map.merge(attrs |> Map.new())

    struct(__MODULE__, attrs)
  end
end
