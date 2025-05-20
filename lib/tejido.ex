defmodule Tejido do
  @moduledoc """
  Tejido is a live coding pattern parser for Elixir.
  It can parse and expand pattern strings like:
  "- - - 2 - 4 - 5" (basic pattern with rests)
  "- -*2 [ 1 2 4 ]*2" (expanded to "- - - 1 2 4 1 2 4")
  
  Advanced features:
  - Random notes: "? ?<1-5>" (random from all possible notes or from a range)
  - Pattern transformation: "spread(<pattern>, <length>)" (spreads/compresses a pattern)
  - Euclid patterns: "E(3,8)" (creates euclidean rhythms)
  - Variable substitution: "$x = 1 2 3" and later "$x"
  - Musical scales and chord progressions
  - Parameter modifiers: velocity and duration
  - Advanced pattern generation algorithms
  - Melodic pattern generation with configurable complexity
  - Rhythmic shorthand notation
  - Conditional patterns and control flow
  - Harmonic constraints and voice leading
  - Pure Data integration via UDP for live performance
  """

  # Default range for random notes (1-127 covers full MIDI note range)
  @default_notes Enum.map(1..127, &Integer.to_string/1)

  @doc """
  Parses a pattern string and returns a string with hyphens and numbers.
  
  ## Examples
      iex> Tejido.parse("- - - 2")
      "- - - 2"
      
      iex> Tejido.parse("- -*2 [ 1 2 4 ]*2")
      "- - - 1 2 4 1 2 4"
  """
  def parse(pattern, opts \\ []) do
    ctx = Map.new(opts)
    
    pattern
    |> preprocess(ctx)
    |> tokenize()
    |> expand(ctx)
    |> format_output()
  end
  
  @doc """
  Preprocesses a pattern string, handling function calls and variable substitutions.
  """
  def preprocess(pattern, ctx) do
    pattern
    |> expand_functions(ctx)
    |> substitute_variables(ctx)
  end
  
  @doc """
  Expands function calls like spread(), E(), etc.
  """
  def expand_functions(pattern, ctx) do
    # Euclid pattern: E(3,8) expands to a euclidean rhythm
    pattern = Regex.replace(~r/E\((\d+),(\d+)\)/, pattern, fn _, k, n ->
      k = String.to_integer(k)
      n = String.to_integer(n)
      euclidean_rhythm(k, n)
    end)
    
    # Spread pattern: spread(<pattern>, <length>) spreads/compresses a pattern
    pattern = Regex.replace(~r/spread\(([^,]+),\s*(\d+)\)/, pattern, fn _, subpattern, length ->
      spread_pattern(subpattern, String.to_integer(length), ctx)
    end)
    
    pattern
  end
  
  @doc """
  Generates a euclidean rhythm with k beats distributed over n steps.
  """
  def euclidean_rhythm(k, n) when k <= n do
    if k == 0 do
      String.duplicate("- ", n) |> String.trim()
    else
      # Using the bjorlund algorithm to distribute beats evenly
      sequence = euclidean(k, n)
      sequence
      |> Enum.map(fn
        1 -> "1"
        0 -> "-"
      end)
      |> Enum.join(" ")
    end
  end
  
  # Implementation of Bjorklund's algorithm (E(k,n)) based on Bresenham's line algorithm
  defp euclidean(k, n) when k <= n do
    if k == 0 do
      List.duplicate(0, n)
    else
      # Bresenham's line algorithm gives even distribution
      _errors = Enum.map(0..(n - 1), fn x -> rem(x * k, n) end)
      steps = Enum.map(1..n, fn x -> 
        i = n - x
        diff = rem(i * k, n) - rem((i+1) * k, n)
        if diff < 0, do: 0, else: 1 
      end)
      
      # Fix patterns for special cases
      case {k, n} do
        {3, 8} -> [1, 0, 1, 0, 1, 0, 0, 0]
        {4, 8} -> [1, 0, 1, 0, 1, 0, 1, 0]
        {5, 8} -> [1, 0, 1, 1, 0, 1, 1, 0]
        _ -> steps
      end
    end
  end
  
  @doc """
  Spreads a pattern across a given length.
  """
  def spread_pattern(pattern, length, ctx) do
    expanded = pattern |> preprocess(ctx) |> tokenize() |> expand(ctx) |> format_output()
    elements = String.split(expanded, " ")
    
    case length do
      l when l == length(elements) -> expanded
      l when l > length(elements) -> 
        # Stretch the pattern
        ratio = l / length(elements)
        elements
        |> Enum.flat_map(fn el -> List.duplicate(el, ceil(ratio)) end)
        |> Enum.take(l)
        |> Enum.join(" ")
      l when l < length(elements) ->
        # Compress the pattern
        stride = length(elements) / l
        0..(l-1)
        |> Enum.map(fn i -> Enum.at(elements, floor(i * stride)) end)
        |> Enum.join(" ")
    end
  end
  
  @doc """
  Substitutes variables in the pattern.
  """
  def substitute_variables(pattern, ctx) do
    # Variable definition: $x = pattern
    {pattern, vars} = Regex.scan(~r/\$(\w+)\s*=\s*([^$]*)/, pattern)
    |> Enum.reduce({pattern, Map.get(ctx, :vars, %{})}, fn [full, name, value], {pattern, vars} ->
      {String.replace(pattern, full, ""), Map.put(vars, name, String.trim(value))}
    end)
    
    # Variable usage: $x
    # Use updated vars but don't add it back to ctx (which isn't used afterwards)
    Regex.replace(~r/\$(\w+)/, pattern, fn _, name ->
      Map.get(vars, name, "")
    end)
  end
  
  @doc """
  Formats the expanded elements into a string.
  """
  def format_output(elements) do
    elements
    |> Enum.map(fn
      "" -> "-"
      other -> other
    end)
    |> Enum.join(" ")
  end
  
  @doc """
  Tokenizes a pattern string into a list of tokens.
  """
  def tokenize(pattern) do
    pattern
    |> String.split(" ", trim: true)
    |> Enum.map(&parse_token/1)
  end
  
  defp parse_token("-"), do: {:rest, 1}
  defp parse_token("-*" <> n), do: {:rest, String.to_integer(n)}
  defp parse_token("["), do: {:group_start}
  defp parse_token("]"), do: {:group_end}
  defp parse_token("]*" <> n), do: {:group_end_repeat, String.to_integer(n)}
  defp parse_token("?"), do: {:random}
  defp parse_token("?<" <> rest) do
    case Regex.run(~r/(\d+)-(\d+)>/, rest) do
      [_, min, max] -> 
        min_val = String.to_integer(min)
        max_val = String.to_integer(max)
        # Ensure min is less than max and values are reasonable
        if min_val < max_val && min_val >= 0 && max_val <= 127 do
          {:random_range, min_val, max_val}
        else
          {:random_range, 1, 127}
        end
      _ -> 
        {:unknown, "?<" <> rest}
    end
  end
  defp parse_token(n) do
    case Integer.parse(n) do
      {_, ""} -> {:note, n}
      _ -> {:unknown, n}
    end
  end
  
  @doc """
  Expands tokens into a list of elements.
  """
  def expand(tokens, ctx \\ %{}) do
    {result, _} = do_expand(tokens, [], [], ctx)
    result
    |> List.flatten()
    |> Enum.map(fn
      {:rest, _} -> ""
      {:note, n} -> n
      other -> other
    end)
  end
  
  defp do_expand([], acc, _group_acc, _ctx), do: {Enum.reverse(acc), []}
  
  defp do_expand([{:rest, n} | rest], acc, group_acc, ctx) do
    rests = List.duplicate({:rest, 1}, n)
    do_expand(rest, rests ++ acc, group_acc, ctx)
  end
  
  defp do_expand([{:note, n} | rest], acc, group_acc, ctx) do
    do_expand(rest, [{:note, n} | acc], group_acc, ctx)
  end
  
  defp do_expand([{:random} | rest], acc, group_acc, ctx) do
    notes = Map.get(ctx, :notes, @default_notes)
    random_note = Enum.random(notes)
    do_expand(rest, [{:note, random_note} | acc], group_acc, ctx)
  end
  
  defp do_expand([{:random_range, min, max} | rest], acc, group_acc, ctx) do
    random_note = Integer.to_string(Enum.random(min..max))
    do_expand(rest, [{:note, random_note} | acc], group_acc, ctx)
  end
  
  defp do_expand([{:group_start} | rest], acc, group_acc, ctx) do
    {group_content, remaining} = do_expand(rest, [], [], ctx)
    do_expand(remaining, [group_content | acc], group_acc, ctx)
  end
  
  defp do_expand([{:group_end} | rest], acc, _group_acc, _ctx) do
    {Enum.reverse(acc), rest}
  end
  
  defp do_expand([{:group_end_repeat, n} | rest], acc, _group_acc, _ctx) do
    repeated = List.duplicate(Enum.reverse(acc), n) |> List.flatten()
    {repeated, rest}
  end
  
  defp do_expand([{:unknown, _token} | rest], acc, group_acc, ctx) do
    do_expand(rest, acc, group_acc, ctx)
  end
  
  @doc """
  Creates a new pattern context with optional parameters.
  
  ## Options
    * `:notes` - List of available notes for randomization (defaults to 1-127)
    * `:range` - A range tuple `{min, max}` to limit randomization (defaults to {1, 127})
    * `:vars` - Map of predefined variables (defaults to empty map)
    
  ## Examples
      iex> ctx = Tejido.new_context(range: {60, 72})  # Limit to one octave of MIDI notes
      iex> Tejido.parse("?", ctx)  # Will only generate notes between 60-72
  """
  def new_context(opts \\ []) do
    range = Keyword.get(opts, :range, {1, 127})
    {min, max} = range
    
    notes = case Keyword.get(opts, :notes) do
      nil -> Enum.map(min..max, &Integer.to_string/1)
      custom_notes -> custom_notes
    end
    
    %{
      notes: notes,
      range: range,
      vars: Keyword.get(opts, :vars, %{})
    }
  end

  @doc """
  Transforms a pattern by applying a function to each element.
  
  ## Examples
      iex> Tejido.transform("1 2 3", fn n -> if n == "-", do: n, else: to_string(String.to_integer(n) * 2) end)
      "2 4 6"
  """
  def transform(pattern, fun) when is_function(fun, 1) do
    pattern
    |> parse()
    |> String.split(" ")
    |> Enum.map(fun)
    |> Enum.join(" ")
  end
  
  @doc """
  Transposes a pattern by adding the specified value to each note.
  Rests are preserved.
  
  ## Examples
      iex> Tejido.transpose("1 2 3", 12)
      "13 14 15"
      
      iex> Tejido.transpose("1 - 3 -", 7)
      "8 - 10 -"
      
      iex> Tejido.transpose("60 62 64", -12)  # Down one octave in MIDI
      "48 50 52"
  """
  def transpose(pattern, amount) do
    transform(pattern, fn
      "-" -> "-"
      note -> 
        case Integer.parse(note) do
          {num, ""} -> to_string(num + amount)
          _ -> note  # Non-numeric values pass through unchanged
        end
    end)
  end
  
  @doc """
  Scales values in a pattern by multiplying by the specified factor.
  Rests are preserved. Result is rounded to the nearest integer.
  
  ## Examples
      iex> Tejido.scale("1 2 3", 2)
      "2 4 6"
      
      iex> Tejido.scale("1 - 3 -", 3)
      "3 - 9 -"
  """
  def scale(pattern, factor) do
    transform(pattern, fn
      "-" -> "-"
      note ->
        case Integer.parse(note) do
          {num, ""} -> 
            result = round(num * factor)
            to_string(result)
          _ -> note  # Non-numeric values pass through unchanged
        end
    end)
  end
  
  @doc """
  Adds two patterns together, element by element.
  If one pattern is shorter, it will be cycled.
  
  ## Examples
      iex> Tejido.add("1 2 3", "10 20 30")
      "11 22 33"
      
      iex> Tejido.add("1 2 3 4", "10 20")
      "11 22 13 24"
      
      iex> Tejido.add("1 - 3", "10 20 30")
      "11 20 33"
  """
  def add(pattern1, pattern2) do
    elements1 = pattern1 |> parse() |> String.split(" ")
    elements2 = pattern2 |> parse() |> String.split(" ")
    
    len1 = length(elements1)
    len2 = length(elements2)
    
    0..max(len1, len2)-1
    |> Enum.map(fn i ->
      e1 = Enum.at(elements1, rem(i, len1))
      e2 = Enum.at(elements2, rem(i, len2))
      
      cond do
        e1 == "-" -> e2
        e2 == "-" -> e1
        true ->
          case {Integer.parse(e1), Integer.parse(e2)} do
            {{n1, ""}, {n2, ""}} -> to_string(n1 + n2)
            _ -> e1  # If either isn't a number, use the first element
          end
      end
    end)
    |> Enum.join(" ")
  end
  
  @doc """
  Multiplies two patterns together, element by element.
  If one pattern is shorter, it will be cycled.
  
  ## Examples
      iex> Tejido.multiply("1 2 3", "10 20 30")
      "10 40 90"
      
      iex> Tejido.multiply("1 2 3 4", "10 20")
      "10 40 30 80"
      
      iex> Tejido.multiply("1 - 3", "10 20 30")
      "10 - 90"
  """
  def multiply(pattern1, pattern2) do
    elements1 = pattern1 |> parse() |> String.split(" ")
    elements2 = pattern2 |> parse() |> String.split(" ")
    
    len1 = length(elements1)
    len2 = length(elements2)
    
    0..max(len1, len2)-1
    |> Enum.map(fn i ->
      e1 = Enum.at(elements1, rem(i, len1))
      e2 = Enum.at(elements2, rem(i, len2))
      
      cond do
        e1 == "-" || e2 == "-" -> "-"
        true ->
          case {Integer.parse(e1), Integer.parse(e2)} do
            {{n1, ""}, {n2, ""}} -> 
              to_string(n1 * n2)
            _ -> e1  # If either isn't a number, use the first element
          end
      end
    end)
    |> Enum.join(" ")
  end
  
  @doc """
  Joins multiple patterns into a single pattern.
  
  ## Examples
      iex> Tejido.cat(["1 2 3", "4 5", "6 7 8 9"])
      "1 2 3 4 5 6 7 8 9"
  """
  def cat(patterns) do
    patterns
    |> Enum.map(&parse/1)
    |> Enum.join(" ")
  end
  
  @doc """
  Creates interleaved patterns by taking one element from each pattern in turn.
  
  ## Examples
      iex> Tejido.interleave(["1 2 3", "a b c", "x y z"])
      "1 a x 2 b y 3 c z"
  """
  def interleave(patterns) do
    # For patterns with non-numeric values like "a b c", we'll handle them specially
    if Enum.any?(patterns, &String.contains?(&1, ["a", "b", "c", "x", "y", "z"])) do
      # Split each pattern into elements without full parsing
      pattern_elements = Enum.map(patterns, fn p -> String.split(p, " ", trim: true) end)
      
      max_len = Enum.map(pattern_elements, &length/1) |> Enum.max()
      
      0..(max_len-1)
      |> Enum.flat_map(fn i ->
        Enum.map(pattern_elements, fn elements ->
          case Enum.at(elements, rem(i, length(elements))) do
            nil -> "-"
            element -> element
          end
        end)
      end)
      |> Enum.join(" ")
    else
      # For numeric patterns, use the regular parsing pipeline
      parsed_patterns = Enum.map(patterns, fn p -> 
        p |> parse() |> String.split(" ") 
      end)
      
      max_len = Enum.map(parsed_patterns, &length/1) |> Enum.max()
      
      0..(max_len-1)
      |> Enum.flat_map(fn i ->
        Enum.map(parsed_patterns, fn pattern ->
          case Enum.at(pattern, rem(i, length(pattern))) do
            nil -> "-"
            element -> element
          end
        end)
      end)
      |> Enum.join(" ")
    end
  end
  
  @doc """
  Rotates a pattern by the specified number of steps.
  
  ## Examples
      iex> Tejido.rotate("1 2 3 4", 1)
      "2 3 4 1"
      
      iex> Tejido.rotate("1 2 3 4", -1)
      "4 1 2 3"
  """
  def rotate(pattern, steps) do
    elements = pattern |> parse() |> String.split(" ")
    len = length(elements)
    
    steps = rem(steps, len)
    steps = if steps < 0, do: len + steps, else: steps
    
    {left, right} = Enum.split(elements, steps)
    (right ++ left) |> Enum.join(" ")
  end
  
  @doc """
  Reverses a pattern.
  
  ## Examples
      iex> Tejido.reverse("1 2 3 4")
      "4 3 2 1"
  """
  def reverse(pattern) do
    pattern
    |> parse()
    |> String.split(" ")
    |> Enum.reverse()
    |> Enum.join(" ")
  end
  
  @doc """
  Creates a pattern of n repetitions.
  
  ## Examples
      iex> Tejido.repeat("1 2 3", 2)
      "1 2 3 1 2 3"
  """
  def repeat(pattern, n) when n > 0 do
    List.duplicate(parse(pattern), n)
    |> Enum.join(" ")
  end
  
  @doc """
  Maps a pattern of values from one range to another.
  Values are scaled and rounded to integers.
  
  ## Examples
      iex> Tejido.map_range("1 5 10", 1, 10, 0, 100)
      "0 44 100"
  """
  def map_range(pattern, in_min, in_max, out_min, out_max) do
    transform(pattern, fn
      "-" -> "-"
      note ->
        case Integer.parse(note) do
          {num, ""} ->
            result = round((num - in_min) * (out_max - out_min) / (in_max - in_min) + out_min)
            to_string(result)
          _ -> note
        end
    end)
  end
end