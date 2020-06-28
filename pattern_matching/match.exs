defmodule PatternMatching.Match do
  @moduledoc false

  alias PatternMatching.SomeData

  def number_to_word(1), do: "One"
  def number_to_word(2), do: "Two"
  def number_to_word(3), do: "Three"
  def number_to_word(4), do: "Four"
  def number_to_word(5), do: "Five"
  def number_to_word(6), do: "Six"
  def number_to_word(7), do: "Seven"
  def number_to_word(8), do: "Eight"
  def number_to_word(9), do: "Nine"
  def number_to_word(_), do: "Only supports numbers 1..9"

  def handle_response({:ok, result}) when is_binary(result) do
    "Got response: #{result}}"
  end

  def handle_response({:ok, result}) do
    "Got response: #{inspect(result)}"
  end

  def handle_response({:error, reason}) when is_binary(reason) do
    "Got error: #{reason}"
  end

  def handle_response({:error, reason}) do
    "Got error: #{inspect(reason)}"
  end

  def handle_data(%SomeData{} = data) do
    {:ok, "Doing some work on #{inspect(data)}"}
  end
end
