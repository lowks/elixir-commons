defmodule Commons.Code.Modules do
  @moduledoc """
  This module contains functions for fetching object code,
  metadata, and other information about a target module.
  """

  @doc """
  Loads the object code for a given module. If the given
  module is not yet loaded, it will be compiled/loaded and
  cached for future processing.
  """
  @spec load_object_code(atom) :: binary
  def load_object_code(mod) when is_atom(mod) do
    case :code.get_object_code(mod) do
      {_module, beam, _beam_path} ->
        beam
      :error ->
        {:module, ^mod}      = Code.ensure_compiled(mod)
        {:file, module_path} = :code.is_loaded(mod)
        [{^mod, module_bin}] = Code.load_file("#{module_path}")
        module_bin
    end
  end

  @doc """
  Loads an attribute for a module given a module name or it's
  object code.

  ## Example

    iex> from_abstract_code(Commons.Code.Stringify, :spec)
    [{{:stringify, 1}, _spec}, ...]

  """
  @spec from_abstract_code(atom, atom) :: [term] | nil
  def from_abstract_code(module, kind) when is_atom(module) and is_atom(kind) do
    get_abstract_code(module) |> do_from_abstract_code(kind)
  end
  def from_abstract_code(beam, kind) when is_binary(beam) and is_atom(kind) do
    get_abstract_code(beam) |> do_from_abstract_code(kind)
  end
  defp do_from_abstract_code(abstract_code, kind) when is_list(abstract_code) do
    for {:attribute, _, abs_kind, value} <- abstract_code, kind == abs_kind, do: value
  end
  defp do_from_abstract_code(_, _), do: nil


  @doc """
  Loads the abstract code for a module given either it's name
  or it's object code.
  """
  @spec get_abstract_code(atom) :: {:ok, term} | nil
  def get_abstract_code(mod) when is_atom(mod) do
    get_chunk(mod, :abstract_code) |> do_get_abstract_code
  end
  def get_abstract_code(beam) when is_binary(beam) do
    get_chunk(beam, :abstract_code) |> do_get_abstract_code
  end
  defp do_get_abstract_code({:ok, {_, [{:abstract_code, {_raw_abstract_v1, abstract_code}}]}}),
    do: abstract_code
  defp do_get_abstract_code({:raw_abstract_v1, abstract_code}),
    do: abstract_code
  defp do_get_abstract_code(_), do: nil

  @doc """
  Loads a chunk for the given module from it's object code.
  You can provide either a module name, or the object code as
  the first parameter.

  ## Examples

    # Loads docs for the module
    iex> get_chunk(Commons.Code.Stringify, 'ExDc')
    ..docs..

    # If you already have the object code, you can pass that in instead of the module
    iex> load_object_code(Commons.Code.Stringify) |> get_chunk('ExDc')
    ..docs..
  """
  def get_chunk(nil, _chunk), do: nil
  def get_chunk(mod, chunk) when is_atom(mod) do
    load_object_code(mod) |> get_chunk(chunk)
  end
  def get_chunk(beam, chunk) when is_binary(beam) do
    case :beam_lib.chunks(beam, [chunk]) do
      {:ok, {_, [{^chunk, result}]}} -> result
      _ ->
        nil
    end
  end

  @doc """
  Load the @doc contents for a given module, function, and arity, given either
  a module name or it's object code as the module argument.
  """
  def get_function_docs(mod, fun, arity) when is_atom(mod) and is_atom(fun) do
    load_object_code(mod)
    |> get_chunk('ExDc')
    |> :erlang.binary_to_term
    |> do_get_function_docs(fun, arity)
  end
  def get_function_docs(beam, fun, arity) when is_binary(beam) and is_atom(fun) do
      beam
      |> get_chunk('ExDc')
      |> :erlang.binary_to_term
      |> do_get_function_docs(fun, arity)
  end
  defp do_get_function_docs({_, [docs: docs, moduledoc: _]}, fun, arity) do
    result = Enum.find(docs, &(find_function_docs(fun, arity, &1)))
    result && extract_function_doc(result) || nil
  end
  defp do_get_function_docs(_, _, _), do: []
  defp find_function_docs(fun, arity, {{fun, arity}, _line, _type, _args, doc})
    when doc != false,
    do: true
  defp find_function_docs(_, _, {{_, _}, _, _, _, _}),
    do: false
  defp extract_function_doc({{_fun, _arity}, _line, _type, _args, doc}), do: doc

  @doc """
  Load the @spec for a given module, function, and arity, and return it in
  it's quoted form. Use `Macro.to_string` to stringify it if you require it
  in that form.
  """
  def get_function_specs(mod, fun, arity) when is_atom(mod) and is_atom(fun) do
    beam_specs(mod) |> do_get_function_specs(fun, arity)
  end
  def get_function_specs(beam, fun, arity) when is_binary(beam) and is_atom(fun) do
    beam_specs(beam) |> do_get_function_specs(fun, arity)
  end
  defp do_get_function_specs(nil, _, _), do: []
  defp do_get_function_specs(specs, fun, arity) when is_list(specs) do
    result = Enum.find(specs, &(find_function_spec(fun, arity, &1)))
    result && extract_function_spec(result) || []
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

  defp beam_specs(module) when is_atom(module) do
    specs = case Kernel.Typespec.beam_specs(module) do
      # Fallback to manual compilation if module is not yet compiled
      nil   -> from_abstract_code(module, :spec)
      specs -> specs
    end
    specs |> beam_specs_tag(:spec)
  end
  defp beam_specs(beam) when is_binary(beam) do
    from_abstract_code(beam, :spec) |> beam_specs_tag(:spec)
  end
  defp beam_specs_tag(nil, _), do: nil
  defp beam_specs_tag(specs, tag) do
    Enum.map(specs, &{tag, &1})
  end

end