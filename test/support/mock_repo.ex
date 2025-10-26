defmodule Gramex.MockRepo do
  def get_by(_schema, _clauses), do: nil
  def insert!(%{__struct__: _} = struct, _opts), do: %{struct | id: 123}
  def update!(%{__struct__: _} = struct, attrs), do: struct |> Map.merge(attrs)
  def transact(fun), do: fun.()
end
