defmodule Commons.Logging.Logger do
  @moduledoc """
  This is the logger used for handling all output of
  debugging, informational, or error messages.

  ## Examples

  # Log a message
  iex> Logger.debug "This is a debugging message!"
  This is a debugging message!
  :ok

  # Log a message with some custom options
  iex> Logger.debug "This is a debugging message!", %LoggerOpts{prefix?: true}
  ==> This is a debugging message!
  :ok

  # Messages which are 
  iex> Logger.debug "This is a debugging message!", %LoggerOpts{level: :info}
  :ok

  iex> Logger.debug %{key1: "Some data I care about", key2: :foo}
  %{
    :key1 => "Some data I care about",
    :key2 => :foo
  }
  %{:key1 => "Some data I care about", key2 => :foo}

  iex> Logger.debug %{key1: "Some data I care about", key2: :foo}, %LoggerOpts{pretty?: false}
  %{:key1 => "Some data I care about", key2 => :foo}
  %{:key1 => "Some data I care about", key2 => :foo}
  """
  import Commons.Code.Stringify, only: [stringify: 1]

  defmodule LoggerOpts do
    @derive Access
    defstruct pretty?:  true,           # Should objects be pretty printed
              colors?:  true,           # Log messages in color
              prefix?:  false,          # Should the default prefix be prepended to the message?
              prefix:   "==> ",         # Prefix messages with this value, if prefix? == true
              width:    120,            # Define the character width of pretty printed objects
              binaries: :infer,         # Uses same values as Inspect.Opts
              level:    :debug,         # The min level of messages to display
              debug:    IO.ANSI.normal, # The color of debug messages, defaults to IO.ANSI.normal
              info:     IO.ANSI.normal, # The color of info messages, defaults to IO.ANSI.normal
              notice:   IO.ANSI.cyan,   # The color of notice messages, defaults to IO.ANSI.cyan
              warn:     IO.ANSI.yellow, # The color of warn messages, defaults to IO.ANSI.yellow
              error:    IO.ANSI.red     # The color of error messages, defaults to IO.ANSI.red
  end

  @doc """
  Initialize the logger. If no options are provided, the defaults
  are used instead. Options can be passed to individual logger calls
  as well to customize on a per-usage basis, but if not provided, the
  options stored in the logger's state are used.
  """
  def init!(opts \\ %LoggerOpts{}) do
    # Use an agent to store logger options
    Agent.start_link(fn -> opts end, name: __MODULE__)
  end

  @doc """
  Configure the logger by providing a new set of options to use.
  """
  @spec configure(LoggerOpts.t) :: :ok
  def configure(%LoggerOpts{} = opts) do
    ensure_started!
    Agent.update(__MODULE__, fn _ -> opts end)
  end

  @doc """
  Set specific logger options. Takes a keyword list of options to set.
  Returns the current set of options after the update.
  """
  @spec configure([{atom, term}]) :: LoggerOpts.t
  def configure([{_, _}|_] = new) do
    ensure_started!
    Agent.get_and_update(__MODULE__, fn current ->
      current = current || %LoggerOpts{}
      options = Enum.reduce(new, current, fn {option, value}, updated ->
        case Map.has_key?(updated, option) do
          true  -> put_in(updated, [option], value)
          false -> updated
        end
      end)
      {options, options}
    end)
  end

  @doc """
  Log a debugging message.

  If the value provided is not a binary, it will be
  stringified and pretty printed to the log. If you pass
  a binary, :ok will be returned. If you pass a non-binary
  value, the value itself will be returned (for easy pipelining).

  You can pass a `LoggerOpts` struct to configure the output. The
  default set of options will be used if you don't pass any.
  """
  def debug(logging, opts \\ nil)
  def debug(message, opts) when is_binary(message),
    do: log(message, :debug, opts)
  def debug(object, opts),
    do: pp(object, :debug, opts)
  @doc """
  Log an informational message with the provided options, or if a
  value other than a binary is provided, the value will be pretty printed.
  """
  def info(logging, opts \\ nil)
  def info(message, opts) when is_binary(message),
    do: log(message, :info, opts)
  def info(object, opts),
    do: pp(object, :info, opts)
  @doc """
  Log a notice message with the provided options, or if a value other
  than a binary is provided, the value will be pretty printed.
  """
  def notice(logging, opts \\ nil)
  def notice(message, opts) when is_binary(message),
    do: log(message, :notice, opts)
  def notice(object, opts),
    do: pp(object, :notice, opts)
  @doc """
  Log a warning message with the provided options, or if a value other
  than a binary is provided, the value will be pretty printed.
  """
  def warn(logging, opts \\ nil)
  def warn(message, opts) when is_binary(message),
    do: log(message, :warn, opts)
  def warn(object, opts),
    do: pp(object, :warn, opts)
  @doc """
  Log an error message with the provided options, or if a value other
  than a binary is provided, the value will be pretty printed.
  """
  def error(logging, opts \\ nil)
  def error(message, opts) when is_binary(message),
    do: log(message, :error, opts)
  def error(object, opts),
    do: pp(object, :error, opts)

  defp log(message, type, opts) do
    opts   = getopts(opts)
    if loggable?(type, opts.level) do
      prefix = opts.prefix? && opts.prefix || ""
      color  = opts[type]
      IO.puts "#{color}#{prefix}#{message}#{IO.ANSI.reset}"
    else
      :ok
    end
  end
  defp pp(obj, type, opts) do
    opts   = getopts(opts)
    if loggable?(type, opts.level) do
      color  = opts[type]
      stringified = case opts.pretty? do
        true  ->
          result    = obj |> Macro.escape |> stringify
          # Check if the width of the output exceeds the
          # width specified in the options, if it does,
          # delegate printing to Inspect.Algebra
          oversize? = result
            |> String.split("\n", trim: true)
            |> Enum.any?(&(byte_size(&1) > opts.width))
          if oversize? do
            pp(obj, opts)
          else
            result
          end
        false -> 
          pp(obj, opts)
      end
      case opts.prefix? do
        true  -> IO.puts "#{color}#{opts.prefix}\n#{stringified}#{IO.ANSI.reset}"
        false -> IO.puts "#{color}#{stringified}#{IO.ANSI.reset}"
      end
    end
    obj
  end
  def pp(obj, opts) do
    obj
    |> Inspect.Algebra.to_doc(%Inspect.Opts{binaries: opts.binaries})
    |> Inspect.Algebra.pretty(opts.width)
  end

  defp loggable?(:debug, level)
    when level in [:debug],
    do: true
  defp loggable?(:info, level)
    when level in [:debug, :info],
    do: true
  defp loggable?(:notice, level)
    when level in [:debug, :info, :notice],
    do: true
  defp loggable?(:debug, _),     do: false
  defp loggable?(:info, _),      do: false
  defp loggable?(:notice, _),    do: false
  defp loggable?(:warn, :error), do: false
  defp loggable?(:warn, _),      do: true
  defp loggable?(:error, _),     do: true

  defp ensure_started! do
    try do
      Agent.get(__MODULE__, &(&1))
    catch
      :exit, {:noproc, _} ->
        init!
    end
    :ok
  end

  defp getopts(opts) do
    opts || (ensure_started! && Agent.get(__MODULE__, &(&1)))
  end
end