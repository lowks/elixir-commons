defmodule Commons.Code do
  @moduledoc """
  This module is a convenience which delegates it's API
  out to modules in the Commons.Code.* namespace. Use this
  instead of the specific submodules where possible.
  """
  use Commons.Macros

  defdelegate stringify(obj), to: Commons.Code.Stringify
end