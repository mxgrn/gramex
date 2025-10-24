defmodule Gramex.MockRepo do
  def get_by(_schema, _clauses), do: nil
  def insert!(%{__struct__: _} = struct), do: %{struct | id: 123}
  def update!(%{__struct__: _} = struct), do: struct
end
