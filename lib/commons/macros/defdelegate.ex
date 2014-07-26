defmodule Commons.Macros.Defdelegate do
  @moduledoc """
  This module contains the macro definition for `defdelegate/2`
  """

  @doc """
  This is an improved version of `Kernel.defdelegate/2` which
  provides documentation and typespecs from the delegated
  function definition.
  """
  defmacro defdelegate(funs, opts) do
    funs = Macro.escape(funs, unquote: true)

    quote bind_quoted: [funs: funs, opts: opts] do
      target = Keyword.get(opts, :to) ||
        raise ArgumentError, "Expected to: to be given as argument"

      # Load beam for the target module for processing
      beam = Commons.Code.Modules.load_object_code(target)

      append_first = Keyword.get(opts, :append_first, false)

      for fun <- List.wrap(funs) do
        {name, args} =
          case Macro.decompose_call(fun) do
            {_, _} = pair -> pair
            _ -> raise ArgumentError, "invalid syntax in defdelegate #{Macro.to_string(fun)}"
          end

        actual_args =
          case append_first and args != [] do
            true  -> tl(args) ++ [hd(args)]
            false -> args
          end

        fun   = Keyword.get(opts, :as, name)
        arity = length(actual_args)
        doc   = Commons.Code.Modules.get_function_docs(beam, fun, arity)
        specs = Commons.Code.Modules.get_function_specs(beam, fun, arity)

        if doc, do: @doc doc
        for spec <- specs do
          @spec unquote(spec)
        end
        def unquote(name)(unquote_splicing(args)) do
          unquote(target).unquote(fun)(unquote_splicing(actual_args))
        end
      end
    end
  end


end