defmodule PatternMatching.SomeData do
  @enforce_keys [:id, :title, :content]

  defstruct [:id, :title, :content, author: "Anonymous"]

  def new(fields), do: struct!(__MODULE__, fields)
end
