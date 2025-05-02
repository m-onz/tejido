defmodule Tajido.Generators do
  @moduledoc """
  Implements advanced pattern generation algorithms for Tajido.
  Provides functions for creating complex patterns through various
  algorithmic approaches.
  """

  @doc """
  Creates a palindrome from a pattern.
  
  ## Examples
      iex> Tajido.Generators.palindrome("1 2 3")
      "1 2 3 2 1"
      
      iex> Tajido.Generators.palindrome("1 2 3", include_middle: false)
      "1 2 3 2 1"
      
      iex> Tajido.Generators.palindrome("1 2 3", include_middle: true)
      "1 2 3 3 2 1"
  """
  def palindrome(pattern, opts \\ []) do
    include_middle = Keyword.get(opts, :include_middle, false)
    
    elements = pattern |> Tajido.parse() |> String.split(" ")
    
    # Create palindrome by reversing and including or excluding the middle element
    reversed = if include_middle do
      Enum.reverse(elements) 
    else
      tl(Enum.reverse(elements))
    end
    
    (elements ++ reversed)
    |> Enum.join(" ")
  end
  
  @doc """
  Repeats each element in a pattern the specified number of times.
  
  ## Examples
      iex> Tajido.Generators.stutter("1 2 3", 2)
      "1 1 2 2 3 3"
      
      iex> Tajido.Generators.stutter("1 2 3", [3, 2, 1])
      "1 1 1 2 2 3"
      
      iex> Tajido.Generators.stutter("1 - 3", 2)
      "1 1 - - 3 3"
  """
  def stutter(pattern, repeats) do
    elements = pattern |> Tajido.parse() |> String.split(" ")
    
    elements
    |> Enum.with_index()
    |> Enum.flat_map(fn {el, idx} ->
      count = if is_list(repeats), do: Enum.at(repeats, rem(idx, length(repeats))), else: repeats
      List.duplicate(el, count)
    end)
    |> Enum.join(" ")
  end
  
  @doc """
  Parses and expands patterns with stutter notation using the '!' symbol.
  
  ## Examples
      iex> Tajido.Generators.expand_stutter("1!3 2!2 3")
      "1 1 1 2 2 3"
      
      iex> Tajido.Generators.expand_stutter("1!3 - 3!2")
      "1 1 1 - 3 3"
  """
  def expand_stutter(pattern) do
    elements = pattern
    |> String.split(" ", trim: true)
    |> Enum.flat_map(fn el ->
      case String.split(el, "!", parts: 2) do
        [note, count] ->
          repeats = case Integer.parse(count) do
            {n, ""} when n > 0 -> n
            _ -> 1
          end
          List.duplicate(note, repeats)
        [note] ->
          [note]
      end
    end)
    
    Enum.join(elements, " ")
  end
  
  @doc """
  Generates random choices based on weighted probabilities.
  
  ## Examples
      iex> Tajido.Generators.weighted_choice([{"1", 0.7}, {"2", 0.2}, {"3", 0.1}], seed: 123)
      "1"
      
      iex> Tajido.Generators.weighted_choice([{"-", 0.2}, {"60", 0.5}, {"67", 0.3}], count: 5, seed: 456)
      "60 67 60 60 -"
  """
  def weighted_choice(choices, opts \\ []) do
    count = Keyword.get(opts, :count, 1)
    
    # If a seed is provided, set it for reproducible results
    if seed = Keyword.get(opts, :seed) do
      :rand.seed(:exsplus, {seed, seed + 1, seed + 2})
    end
    
    # Calculate cumulative probabilities
    {cum_choices, _} = Enum.map_reduce(choices, 0, fn {choice, prob}, acc ->
      {{choice, acc + prob}, acc + prob}
    end)
    
    # Generate the requested number of choices
    choices = Enum.map(1..count, fn _ ->
      random = :rand.uniform()
      
      # Find the first choice where random <= cumulative probability
      {choice, _} = Enum.find(cum_choices, List.first(choices), fn {_, cum_prob} -> 
        random <= cum_prob
      end)
      
      choice
    end)
    
    Enum.join(choices, " ")
  end

  @doc """
  Implements L-system pattern generation.
  
  L-systems are a type of formal grammar used to model growth processes
  and can generate complex fractal-like patterns.
  
  ## Examples
      iex> Tajido.Generators.l_system("1", [{"1", "1 2"}, {"2", "2 1"}], 2)
      "1 2 2 1"
      
      iex> Tajido.Generators.l_system("a", [{"a", "a b"}, {"b", "a"}], 3)
      "a b a"
  """
  def l_system(axiom, rules, iterations) do
    # Convert rules to a map for efficient lookup
    rule_map = Map.new(rules)
    
    # Helper function to apply rules to a single token
    apply_rule = fn token ->
      Map.get(rule_map, token, token)
    end
    
    # Apply rules repeatedly for the requested number of iterations
    result = Enum.reduce(1..iterations, axiom, fn _, acc ->
      acc
      |> String.split(" ", trim: true)
      |> Enum.map(apply_rule)
      |> Enum.join(" ")
    end)
    
    result
  end
  
  @doc """
  Generates a polyrhythm pattern by interleaving patterns with different speeds.
  
  ## Examples
      iex> Tajido.Generators.polyrhythm(["1 2 3 4", "a b c"], [4, 3])
      "1 a 2 3 b 4 c"
      
      iex> Tajido.Generators.polyrhythm(["1 2", "a b c d"], [2, 4])
      "1 a 2 b - c - d"
  """
  def polyrhythm(patterns, cycles) do
    # Expand each pattern to match its cycle length
    expanded_patterns = Enum.zip(patterns, cycles)
    |> Enum.map(fn {pattern, cycle} ->
      elements = pattern |> Tajido.parse() |> String.split(" ")
      cycle_elements = cycle * length(elements)
      
      # Stretch or compress the pattern to fit precisely in the cycle
      stride = length(elements) / cycle_elements
      
      0..(cycle_elements-1)
      |> Enum.map(fn i -> 
        idx = floor(i * stride)
        Enum.at(elements, idx, "-")
      end)
    end)
    
    # Find the least common multiple of all cycles to get the pattern length
    lcm = Enum.reduce(cycles, 1, fn cycle, acc ->
      div(cycle * acc, Integer.gcd(cycle, acc))
    end)
    
    # Interleave patterns based on their relative positions in the cycle
    0..(lcm-1)
    |> Enum.map(fn i ->
      Enum.zip(expanded_patterns, cycles)
      |> Enum.filter(fn {_, cycle} -> 
        rem(i, div(lcm, cycle)) == 0
      end)
      |> Enum.map(fn {elements, cycle} ->
        cycle_position = div(i, div(lcm, cycle))
        Enum.at(elements, rem(cycle_position, length(elements)), "-")
      end)
      |> Enum.join(" ")
    end)
    |> Enum.join(" ")
  end
  
  @doc """
  Creates overlapping layers of patterns with independent timelines.
  
  ## Examples
      iex> Tajido.Generators.layers([
      ...>   {"1 2 3 4", %{speed: 1.0}},
      ...>   {"a b", %{speed: 0.5}}
      ...> ])
      "1 2 3 4 1 a 2 3 4 2 b"
  """
  def layers(layer_configs) do
    # Expand each layer according to its speed
    expanded_layers = Enum.map(layer_configs, fn {pattern, config} ->
      elements = pattern |> Tajido.parse() |> String.split(" ")
      speed = Map.get(config, :speed, 1.0)
      
      # Calculate how many elements to generate based on speed
      {elements, speed}
    end)
    
    # Find the least common multiple of all speeds to get a cycle length
    speeds = Enum.map(expanded_layers, fn {_, speed} -> speed end)
    # Manually implement GCD for floats
    float_gcd = fn
      _gcd_fn, a, b when b < 0.0001 -> a
      gcd_fn, a, b -> gcd_fn.(gcd_fn, b, :math.fmod(a, b))
    end
    
    # Define LCM based on GCD
    float_lcm = fn a, b -> (a * b) / float_gcd.(float_gcd, a, b) end
    
    # Find the LCM of all speeds
    lcm_speed = Enum.reduce(speeds, 1.0, fn speed, acc ->
      float_lcm.(speed, acc)
    end)
    
    # Calculate how many steps we need
    max_steps = ceil(lcm_speed * 10) # Arbitrary length, adjust as needed
    
    # Generate the sequence by iterating over time
    0..(max_steps-1)
    |> Enum.flat_map(fn step ->
      step_time = step / 10.0
      
      # Find all elements that should be played at this time step
      Enum.flat_map(expanded_layers, fn {elements, speed} ->
        element_duration = 1.0 / speed
        element_index = floor(step_time / element_duration) |> rem(length(elements))
        
        # Check if a new element starts exactly at this time step
        if abs(rem(step_time, element_duration)) < 0.01 do
          [Enum.at(elements, element_index)]
        else
          []
        end
      end)
    end)
    |> Enum.join(" ")
  end
end