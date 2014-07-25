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
        doc   = Commons.Macros.Defdelegate.get_function_docs(target, fun, arity)
        specs = Commons.Macros.Defdelegate.get_function_specs(target, fun, arity)

        @doc doc
        for spec <- specs do
          @spec unquote(spec)
        end
        def unquote(name)(unquote_splicing(args)) do
          unquote(target).unquote(fun)(unquote_splicing(actual_args))
        end
      end
    end
  end

  @missing_docs "No docs available for this function."
  def get_function_docs(mod, fun, arity) when is_atom(mod) and is_atom(fun) do
    case Code.get_docs(mod, :docs) do
      nil  -> @missing_docs
      docs ->
        result = Enum.find(docs, &(find_function_docs(fun, arity, &1)))
        result && extract_function_doc(result) || @missing_docs
    end
  end
  defp find_function_docs(fun, arity, {{fun, arity}, _line, _type, _args, doc})
    when doc != false,
    do: true
  defp find_function_docs(_, _, {{_, _}, _, _, _, _}),
    do: false
  defp extract_function_doc({{_fun, _arity}, _line, _type, _args, doc}), do: doc

  def get_function_specs(mod, fun, arity) when is_atom(mod) and is_atom(fun) do
    case beam_specs(mod) do
      nil   -> []
      specs ->
        result = Enum.find(specs, &(find_function_spec(fun, arity, &1)))
        result && extract_function_spec(result) || []
    end
  end
  defp find_function_spec(fun, arity, {:spec, {{fun, arity}, _spec}}),
    do: true
  defp find_function_spec(_, _, {_, {{_, _}, _}}),
    do: false
  defp extract_function_spec({_kind, {{fun, _arity}, spec}}) do
    Enum.map(spec, fn s ->
      Kernel.Typespec.spec_to_ast(fun, s)
    end)
  end

  defp beam_specs(module) do
    specs = beam_specs_tag(Kernel.Typespec.beam_specs(module), :spec)
    callbacks = beam_specs_tag(Kernel.Typespec.beam_callbacks(module), :callback)
    specs && callbacks && Enum.concat(specs, callbacks)
  end
  defp beam_specs_tag(nil, _), do: nil
  defp beam_specs_tag(specs, tag) do
    Enum.map(specs, &{tag, &1})
  end
end