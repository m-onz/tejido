defmodule Tajido.Conditionals do
  @moduledoc """
  Provides conditional pattern generation and execution based on runtime rules.
  Allows patterns to change dynamically based on conditions like beat number, 
  repetition count, or other state.
  """

  @doc """
  Selects between two patterns based on a condition.
  
  ## Examples
      iex> Tajido.Conditionals.when_("true", "1 2 3", "4 5 6")
      "1 2 3"
      
      iex> Tajido.Conditionals.when_("false", "1 2 3", "4 5 6")
      "4 5 6"
      
      iex> Tajido.Conditionals.when_("2 > 1", "1 2 3", "4 5 6")
      "1 2 3"
  """
  def when_(condition, true_pattern, false_pattern) do
    result = case evaluate_condition(condition) do
      true -> true_pattern
      false -> false_pattern
      _ -> false_pattern  # Default to false pattern if condition can't be evaluated
    end
    
    result
  end

  @doc """
  Executes a pattern every nth repetition, using a different pattern for other repetitions.
  Uses a counter that's either provided or fetched from an internal state.
  
  ## Examples
      iex> Tajido.Conditionals.every(3, "1 2 3", "4 5 6", counter: 1)
      "4 5 6"
      
      iex> Tajido.Conditionals.every(3, "1 2 3", "4 5 6", counter: 3)
      "1 2 3"
      
      iex> Tajido.Conditionals.every(4, "1 2 3", "4 5 6", counter: 4)
      "1 2 3"
      
      iex> Tajido.Conditionals.every(4, "1 2 3", "4 5 6", counter: 6)
      "4 5 6"
  """
  def every(n, true_pattern, false_pattern, opts \\ []) do
    counter = Keyword.get(opts, :counter, 1)
    
    if rem(counter, n) == 0 do
      true_pattern
    else
      false_pattern
    end
  end

  @doc """
  Switches between patterns based on a list of state values.
  
  ## Examples
      iex> Tajido.Conditionals.switch(1, ["1 2 3", "4 5 6", "7 8 9"])
      "4 5 6"
      
      iex> Tajido.Conditionals.switch(0, ["1 2 3", "4 5 6", "7 8 9"])
      "1 2 3"
      
      iex> Tajido.Conditionals.switch(5, ["1 2 3", "4 5 6", "7 8 9"])
      "7 8 9"
  """
  def switch(state, patterns) do
    index = case state do
      i when is_integer(i) -> i
      _ -> 0
    end
    
    # Use modulo to handle cases where state exceeds pattern list length
    Enum.at(patterns, rem(index, length(patterns)), List.first(patterns))
  end

  @doc """
  Creates patterns based on sequential iteration through a list on each repetition.
  
  ## Examples
      iex> sequence = ["1 2 3", "4 5 6", "7 8 9"]
      iex> Tajido.Conditionals.sequence(sequence, counter: 0)
      "1 2 3"
      
      iex> sequence = ["1 2 3", "4 5 6", "7 8 9"]
      iex> Tajido.Conditionals.sequence(sequence, counter: 1)
      "4 5 6"
      
      iex> sequence = ["1 2 3", "4 5 6", "7 8 9"]
      iex> Tajido.Conditionals.sequence(sequence, counter: 3)
      "1 2 3"
  """
  def sequence(patterns, opts \\ []) do
    counter = Keyword.get(opts, :counter, 0)
    
    Enum.at(patterns, rem(counter, length(patterns)), List.first(patterns))
  end

  @doc """
  Combines patterns based on the current beat in a measure.
  Takes a map of beat numbers to patterns.
  
  ## Examples
      iex> beats = %{
      ...>   1 => "60 62 64",   # On beat 1
      ...>   3 => "67 69",      # On beat 3
      ...>   :other => "70"     # On other beats
      ...> }
      iex> Tajido.Conditionals.on_beat(beats, beat: 1)
      "60 62 64"
      
      iex> Tajido.Conditionals.on_beat(beats, beat: 3)
      "67 69"
      
      iex> Tajido.Conditionals.on_beat(beats, beat: 2)
      "70"
  """
  def on_beat(beat_patterns, opts \\ []) do
    beat = Keyword.get(opts, :beat, 1)
    
    # First look for direct match for the current beat
    case Map.get(beat_patterns, beat) do
      nil -> 
        # If no direct match, check for an :other key as fallback
        Map.get(beat_patterns, :other, "")
      pattern -> 
        pattern
    end
  end
  
  @doc """
  Combines patterns based on the current phase in a cycle.
  Takes a value between 0 and 1 representing the phase position,
  and executes patterns at specific phase ranges.
  
  ## Examples
      iex> phases = %{
      ...>   0.0..0.25 => "60 62 64",    # First quarter
      ...>   0.5..0.75 => "67 69",       # Third quarter
      ...>   :other => "70"              # At other phases
      ...> }
      iex> Tajido.Conditionals.on_phase(phases, phase: 0.1)
      "60 62 64"
      
      iex> Tajido.Conditionals.on_phase(phases, phase: 0.6)
      "67 69"
      
      iex> Tajido.Conditionals.on_phase(phases, phase: 0.8)
      "70"
  """
  def on_phase(phase_patterns, opts \\ []) do
    phase = Keyword.get(opts, :phase, 0.0)
    
    # Find the phase range that includes the current phase
    matching_phase = Enum.find(Map.keys(phase_patterns), fn
      %Range{} = range -> phase >= range.first && phase <= range.last
      _ -> false
    end)
    
    case matching_phase do
      nil -> 
        # If no direct match, check for an :other key as fallback
        Map.get(phase_patterns, :other, "")
      range -> 
        Map.get(phase_patterns, range)
    end
  end
  
  @doc """
  Provides a way to select patterns based on probability.
  
  ## Examples
      iex> patterns = %{
      ...>   "60 62 64" => 0.7,  # 70% chance
      ...>   "67 69 71" => 0.2,  # 20% chance
      ...>   "72 74 76" => 0.1   # 10% chance
      ...> }
      iex> Tajido.Conditionals.weighted(patterns, seed: 123)
      "60 62 64"
  """
  def weighted(weighted_patterns, opts \\ []) do
    # Convert to list of {pattern, weight} tuples for the choice function
    choices = Enum.map(weighted_patterns, fn {pattern, weight} -> 
      {pattern, weight}
    end)
    
    seed = Keyword.get(opts, :seed)
    
    Tajido.Generators.weighted_choice(choices, seed: seed)
  end
  
  # Private helpers
  
  # Evaluates a condition string as Elixir code
  defp evaluate_condition(condition) do
    case condition do
      "true" -> true
      "false" -> false
      expr ->
        try do
          {result, _} = Code.eval_string(expr)
          !!result  # Convert any result to boolean
        rescue
          _ -> false
        end
    end
  end
end