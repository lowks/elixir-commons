defmodule CommonsMacroTest do
  use    ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import IEx.Helpers, only: [h: 1, s: 1]

  test "can get help for delegated function" do
    expected = """
      * def stringify(obj)

      Takes a schema in quoted form and produces a string
      representation of that schema for printing or writing
      to disk.


      """
  
    assert capture_io(fn ->
      h Commons.Code.stringify
    end) == expected
  end

  test "can get typespecs for delegated function" do
    expected = """
    @spec stringify(term()) :: binary()
    """

    assert capture_io(fn ->
      s Commons.Code.stringify
    end) == expected
  end
end