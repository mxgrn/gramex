defmodule Gramex.Utils do
  @doc """
  Converts keys to strings.
  """
  def deep_stringify_keys(%{} = map) do
    Map.new(map, fn {k, v} -> {to_string(k), deep_stringify_keys(v)} end)
  end

  def deep_stringify_keys(list) when is_list(list) do
    Enum.map(list, &deep_stringify_keys/1)
  end

  def deep_stringify_keys(v), do: v
end
