defmodule Gramex.Testing.Sessions.User do
  defstruct [:id, :is_bot, :first_name, :last_name, :username, :language_code]

  def new(attrs \\ []) when is_list(attrs) do
    attrs =
      %{
        id: :rand.uniform(1_000_000_000),
        is_bot: false,
        first_name: "FirstName",
        last_name: nil,
        username: nil,
        language_code: "en"
      }
      |> Map.merge(attrs |> Map.new())

    struct(__MODULE__, attrs)
  end
end
