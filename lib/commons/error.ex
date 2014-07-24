defmodule CommonsError do
  @moduledoc """
  This module defines the exception type that all
  functions which throw errors within elixir-commons
  will use.
  """
  import Commons.Code.Stringify, only: [stringify: 1]

  defexception [:message, :data]

  def exception(message) do
    %CommonsError{message: message, data: nil}
  end

  def exception(message, value) do
    stringified = stringify(value)
    "#{message}\n#{stringified}"
    %CommonsError{message: message, data: value}
  end
end