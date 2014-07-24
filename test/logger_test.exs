defmodule LoggerTest do
  use ExUnit.Case
  Mix.shell(Mix.Shell.Process)
  doctest Commons.Logging.Logger

end