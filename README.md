# Intro to Elixir

## Elixir interactive shell IEx is your friend
Type `iex` in your terminal and something like this should show up:

```
Erlang/OTP 22 [erts-10.5.3] [source] [64-bit] [smp:12:12] [ds:12:12:10] [async-threads:1] [hipe]

Interactive Elixir (1.9.1) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)>
```

Quick tip: If we accidentally get into a multiline expressions in IEx we can exit the multiline with `#iex:break` 

Multiline look something like this:
```
iex(1)> <ops typo somewhere> 
...(1)> 
...(1)>
...(1)> #iex:break
```

### Documentation
We can lookup the documentation on modules and its functions using the `h` command. It's a great
alternative to quickly get to documentation on modules and functions. This also true for our own
modules and public functions, use `@moduledoc` to document modules and `@doc` for the
public functions.

```
iex(1)> h E.<tab>
Elixir         Enum           Enumerable     ErlangError    Exception

iex(1)> h Enum.<tab>
EmptyError           OutOfBoundsError     all?/1
all?/2               any?/1               any?/2 ... 

iex(1)> h Enum.all?
<shows documentation>
```

Wonder what `all?/1` and `all?/2` mean? 

In Elixir functions with different number of arguments (arity) are treated
as different functions. The `?` in the end of the function name is a convention
when it returns `true` or `false`.

### The operator `=` is not assignment
In many languages the `=` operator is the assignment operator. In Elixir its
different, let's explore it more in IEx.

```
iex(1)> a = {1,2,3}
{1,2,3}

iex(2)> {1,2,3} = a
{1,2,3}

iex(3)> {x,2,3} = a
{1,2,3}

iex(4)> x
1

iex(5)> {x, 3, 3} = a
** (MatchError) no match of right hand side value: {1,2,3}

iex(6)> {:ok, result} = {:ok, "We did it!"}
{:ok, "We did it!"}

iex(7)> result
"We did it!"

iex(8)> false = false
false

iex(9)> true = "true"
** (MatchError) no match of right hand side value: "true"

iex(10)> a = true
true

iex(11)> {^a, b} = {true, false}
{true, false}

iex(12)> {^a, b} = {false, false}
** (MatchError) no match of right hand side value: {false, false}
```

In Elixir the `=` is a match operator, it tries to match the value on the `left` side 
to the value on the `right`. For `a = {1,2,3}` it binds the value to variable `a`,
because it's a match operator the reverse is also valid `{1,2,3} = a`.

If we want to avoid having variables be re-bound when doing matches,
then we can use the pin `^` operator to reference the value it holds for the match
(see line 10-12 in examples above).

### Pattern matching
Let's explore pattern matching some more because it's not just for the match operator. Within
your editor navigate to `pattern_matching/match.exs` to get familiar with the code.

We can compile the file with `c`, depending on where we start `iex` the path might differ,
but we have helpers available, like `ls`, check out the full list of [IEx.helpers](https://hexdocs.pm/iex/IEx.Helpers.html#content).
The order of which we compile matters, the `%{}SomeData` struct is used in `match.exs` and needs to be compiled first.

```
iex(1)> c "pattern_matching/some_data.exs"
[PatternMatching.SomeData]

iex(2)> c "pattern_matching/match.exs"
[PatternMatching.Match]

# we can alias both modules at once by adding `;` 
iex(3)> alias PatternMatching.Match; alias PatternMatching.SomeData
    
iex(4)> Match.number_to_word(3)
"Three"

iex(5)> Match.number_to_word(7)
"Seven"

iex(6)> Match.number_to_word(11)
"Only supports numbers 1..9"

iex(7)> Match.number_to_word(%{something_else: "something"})
"Only supports numbers 1..9"
```

Pattern matching are often used to match on tagged responses like this:

```
iex(8)> msg = {:ok, %{status: "All good"}}
{:ok, %{status: "All good"}}

iex(9)> Match.handle_response(msg) 
"Got response: %{status: \"All good\"}"

iex(10)> Match.handle_response({:error, "Code red!"}) 
"Got error: Code red!"

```

If we want to be more strict when matching, we can define a `struct` to match against and get 
some compile time guaranties in the process. There's a struct defined in `pattern_matching/some_data.exs` 
and `handle_data/1` in `pattern_matching/match.exs` which expects this struct.

Notice how we use `alias PatternMatching.SomeData` at the top of `match.exs` so we can
to refer to it as `SomeData` instead of the fully-qualified name.

Let's try to handle some data:

```
iex(1)> Match.handle_data(%{id: 1, title: "Hello", content: "World", author: "Anonymous"})
** (FunctionClauseError) no function clause matching in PatternMatching.Match.handle_data/1
``` 

We tried to pass a regular map to `handle_data/1` but if we look at the function signature 
it looks like this `handle_data(%SomeData{} = data) do ... end`  where `%SomeData{}` is the struct.

```
iex(2)> data = SomeData.new(id: 1, title: "Hello")
** (ArgumentError) the following keys must also be given when building struct PatternMatching.SomeData: [:content]

iex(3)> data = SomeData.new(id: 1, title: "Hello", content: "World")
%PatternMatching.SomeData{
  author: "Anonymous",
  content: "World",
  id: 1,
  title: "Hello"
}

iex(4)> {:ok, response} = Match.handle_data(data)
{:ok, <the response>}

```

## Processes

Processes in Elixir is not to be confused with processes in your operating system. Elixir processes are extremely
lightweight, each with their own memory, stack and heap. They don't share anything, communication is done through message
passing. 
 
It's not uncommon to have many thousands of these tiny processes running in a system. Working  with processes are
commonly done through abstractions. One of these are called GenServers. 

This is a big topic, so we'll just get our feet warm with some really simple stuff. Let's start by creating
a new project `mix new simple_otp --sup`, the `--sup` flag is for adding some boilerplate code for supervision.

Now in `simple_otp/lib/simple_otp` create a `simple_process.ex` file with the following:

```elixir
defmodule SimpleOtp.SimpleProcess do
  @moduledoc false

  use GenServer

  # Client

  def start_link(_opts) do
    initial_state = %{}
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  @doc """
  Create a key value entry in the process
  """
  def create(key, val) do
    GenServer.cast(__MODULE__, {:create, key, val})
  end

  @doc """
  Get value by key
  """
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @doc """
  Reset the state of the process
  """
  def reset() do
    GenServer.cast(__MODULE__, :reset)
  end

  @doc """
  Simulate blocking
  """
  def block() do
    GenServer.cast(__MODULE__, :block)
  end

  # Server (callbacks)

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:get, :all}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    response =
      case Map.fetch(state, key) do
        {:ok, x} -> x
        _ -> "Could not find #{inspect(key)}"
      end

    {:reply, response, state}
  end

  @impl true
  def handle_cast({:create, :all, _val}, state) do
    IO.puts("Sorry! The :all key is reserved for retrieving the whole state.")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:create, key, val}, state) do
    new_state = Map.put(state, key, val)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:block, state) do
    # Simulate doing work that takes times
    :timer.sleep(10_000)
    IO.puts("Sorry did you wait for me?")

    {:noreply, state}
  end
end

```

Then add the line `{SimpleOtp.SimpleProcess, []}` to `lib/simple_otp/application.ex` so the
process starts under the main supervisor.

```elixir
    children = [
      # Starts a worker by calling: SimpleOtp.Worker.start_link(arg)
      # {SimpleOtp.Worker, arg}
      SimpleOtp.SimpleProcess
    ]

```

Let's also use the `SimpleOtp` context to call our GenServer, you can think of it like a public api. 
Replace the content of `simple_otp/lib/simple_otp.ex` with the following:

```elixir
defmodule SimpleOtp do
  @moduledoc """
  This module defines the external API for the SimpleOtp example.
  Delegates to a public function in `simple_otp/*.ex`.
  """

  @doc delegate_to: {__MODULE__.SimpleProcess, :create, 2}
  defdelegate create(key, val), to: __MODULE__.SimpleProcess

  @doc delegate_to: {__MODULE__.SimpleProcess, :get, 1}
  defdelegate get(key), to: __MODULE__.SimpleProcess

  @doc delegate_to: {__MODULE__.SimpleProcess, :reset, 0}
  defdelegate reset(), to: __MODULE__.SimpleProcess

  @doc delegate_to: {__MODULE__.SimpleProcess, :block, 0}
  defdelegate block(), to: __MODULE__.SimpleProcess
end

```

This delegates to `SimpleOtp.SimpleProcess`, the `__MODULE__` is just a way to refer to itself,
here its `SimpleOtp`. Using `__MODULE__` would make it easier to rename modules and contexts.

We also need to adjust the test, `mix test` will fail because we removed the generated code. In
`test/simple_otp_test.exs`, change it for the code below. Feel free to add more tests, we'll just
add one for now.

```elixir
defmodule SimpleOtpTest do
  use ExUnit.Case, async: true

  test "add state to process", _ do
    assert SimpleOtp.create(:hello, "world") == :ok
    assert SimpleOtp.get(:hello) == "world"
  end
end

```
Let's compile the project and take it for a spin.

In your terminal, go to the project folder `cd simple_otp` and run the command `iex -S mix` it
should compile and enter an IEx session for you so we can start to play with the GenServer through
our `SimpleOtp` module. 

```
iex(1)> SimpleOtp.create(:my_key, "my_value")
:ok

iex(2)> SimpleOtp.create(:other_key, %{map: "X marks the spot"})
:ok

iex(3)> SimpleOtp.get(:my_key)
"my_value"

iex(4)> SimpleOtp.get(:other_key)
%{map: "X marks the spot"}

iex(5)> SimpleOtp.get(:all)
%{my_key: "my_value", other_key: %{map: "X marks the spot"}}

# Because we named the process the same name as the module we can find the pid by name
iex(6)> pid = Process.whereis(SimpleOtp.SimpleProcess)
#PID<0.135.0>

# Lets kill it *evil*
iex(7)> Process.exit(pid, :kaboom)
true

# Notice hot the supervisor restarted the process (different pid)
iex(8)> pid = Process.whereis(SimpleOtp.SimpleProcess)
#PID<0.150.0>

# You can interspect the Erlang VM (BEAM)
iex(9)> :observer.start

# A single process is syncronisation point, it will act as a queue, concurrency is done
# through the use of multiple processes each having its own isolated state.

iex(10)> SimpleOtp.create(:some_key, "some_value")
:ok

iex(11)> SimpleOtp.create(:your_keys, "breaking in")
:ok

iex(11)> SimpleOtp.block()
:ok

iex(12)> SimpleOtp.get(:all)
```
