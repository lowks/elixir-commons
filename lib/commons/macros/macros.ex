defmodule Commons.Macros do
  @moduledoc """
  To use the macros provided by Commons, just do:

    defmodule MyModule do
      use Commons.Macros

      defdelegate duplcate(s, times), to: String
    end

  The macros themselves are defined in their own modules. You
  can view their documentation there. Keep in mind that by "using"
  this module, you could be overriding standard library macros in
  some cases. Currently the only case of that is `defdelegate`, which
  modifies the original to allow proxying docs and typespecs to the
  delegating module.
  """

  defmacro __using__(_) do
    quote do
      import Kernel, except: [defdelegate: 2]
      require Commons.Macros.Defdelegate
      import Commons.Macros.Defdelegate, only: [defdelegate: 2]
    end
  end
end