defmodule Tajido.Rhythm do
  @moduledoc """
  Provides shorthand notation for rhythmic values and time signatures.
  Allows expressing note durations using conventional music notation.
  """

  @doc """
  Maps rhythmic notation to durations in beats.
  
  Supported notation:
  - "/1" - Whole note (4 beats in 4/4)
  - "/2" - Half note (2 beats in 4/4)
  - "/4" - Quarter note (1 beat in 4/4)
  - "/8" - Eighth note (0.5 beats in 4/4)
  - "/16" - Sixteenth note (0.25 beats in 4/4)
  - "/32" - Thirty-second note (0.125 beats in 4/4)
  
  Dotted notes (1.5x duration):
  - "/4." - Dotted quarter note (1.5 beats in 4/4)
  
  Tuplets:
  - "/4t" - Quarter note triplet (0.67 beats in 4/4)
  - "/8t" - Eighth note triplet (0.33 beats in 4/4)
  
  ## Examples
      iex> Tajido.Rhythm.duration("/1")
      4.0
      
      iex> Tajido.Rhythm.duration("/4")
      1.0
      
      iex> Tajido.Rhythm.duration("/8.")
      0.75
      
      iex> Tajido.Rhythm.duration("/4t")
      0.67
  """
  def duration(rhythm_value) do
    case parse_rhythm(rhythm_value) do
      {base, dotted, triplet} ->
        base_duration = case base do
          1 -> 4.0
          2 -> 2.0
          4 -> 1.0
          8 -> 0.5
          16 -> 0.25
          32 -> 0.125
          _ -> 1.0 # Default to quarter note
        end
        
        # Apply dotted note adjustment (1.5x)
        dot_multiplier = if dotted, do: 1.5, else: 1.0
        
        # Apply triplet adjustment (2/3)
        triplet_multiplier = if triplet, do: 2/3, else: 1.0
        
        base_duration * dot_multiplier * triplet_multiplier
        |> Float.round(2)
      
      _ -> 1.0 # Default to quarter note if parsing fails
    end
  end
  
  @doc """
  Parses a rhythm string into a pattern of durations.
  
  ## Examples
      iex> Tajido.Rhythm.parse("/4 /8 /8 /4")
      "1.0 0.5 0.5 1.0"
      
      iex> Tajido.Rhythm.parse("/4. /8 /8 /4")
      "1.5 0.5 0.5 1.0"
      
      iex> Tajido.Rhythm.parse("/4t /4t /4t")
      "0.67 0.67 0.67"
  """
  def parse(pattern) do
    pattern
    |> String.split(" ", trim: true)
    |> Enum.map(fn token ->
      case token do
        "/" <> _ -> duration(token) |> to_string()
        _ -> token # Pass through non-rhythm values
      end
    end)
    |> Enum.join(" ")
  end
  
  @doc """
  Expands rhythmic patterns into note patterns with durations.
  
  ## Examples
      iex> Tajido.Rhythm.expand_rhythm("60", "/4 /8 /8 /4")
      "60:1.0 60:0.5 60:0.5 60:1.0"
      
      iex> Tajido.Rhythm.expand_rhythm("60 64 67", "/4 /8 /8")
      "60:1.0 64:0.5 67:0.5 60:1.0 64:0.5 67:0.5"
      
      iex> Tajido.Rhythm.expand_rhythm("60 - 67", "/4. /8 /4")
      "60:1.5 -:0.5 67:1.0 60:1.5 -:0.5 67:1.0"
  """
  def expand_rhythm(notes, rhythm_pattern) do
    note_tokens = notes |> String.split(" ", trim: true)
    rhythm_tokens = rhythm_pattern |> String.split(" ", trim: true)
    
    # Create a cycle of notes and rhythms
    cycle_length = lcm(length(note_tokens), length(rhythm_tokens))
    
    note_cycle = cycle(note_tokens, cycle_length)
    rhythm_cycle = cycle(rhythm_tokens, cycle_length)
    |> Enum.map(fn r ->
      case r do
        "/" <> _ -> duration(r) |> to_string()
        _ -> r
      end
    end)
    
    # Combine notes with durations
    Enum.zip(note_cycle, rhythm_cycle)
    |> Enum.map(fn {note, dur} -> "#{note}:#{dur}" end)
    |> Enum.join(" ")
  end
  
  @doc """
  Applies swing feel to a rhythm pattern.
  
  ## Examples
      iex> Tajido.Rhythm.swing("1 2 3 4", 0.33)
      "1:1.33 2:0.67 3:1.33 4:0.67"
      
      iex> Tajido.Rhythm.swing("1:1 2:1 3:1 4:1", 0.2)
      "1:1.2 2:0.8 3:1.2 4:0.8"
  """
  def swing(pattern, swing_ratio) do
    elements = pattern |> String.split(" ", trim: true)
    
    # Process pairs of notes
    {result, _} = Enum.chunk_every(elements, 2, 2, [])
    |> Enum.map_reduce(0, fn pair, offset ->
      case pair do
        [first, second] ->
          # Get current durations or default to 1.0
          {first_note, first_dur} = case String.split(first, ":", parts: 2) do
            [note, dur] -> {note, String.to_float(dur)}
            [note] -> {note, 1.0}
          end
          
          {second_note, second_dur} = case String.split(second, ":", parts: 2) do
            [note, dur] -> {note, String.to_float(dur)}
            [note] -> {note, 1.0}
          end
          
          # Calculate total duration of the pair
          total_dur = first_dur + second_dur
          
          # Apply swing
          first_swung = total_dur * (0.5 + swing_ratio / 2)
          second_swung = total_dur * (0.5 - swing_ratio / 2)
          
          # Format back with new durations
          {["#{first_note}:#{Float.round(first_swung, 2)}", "#{second_note}:#{Float.round(second_swung, 2)}"], 
           offset + total_dur}
        
        [single] ->
          # If there's an odd number of elements, leave the last one as is
          {[single], offset + 1.0}
        
        [] ->
          {[], offset}
      end
    end)
    
    List.flatten(result) |> Enum.join(" ")
  end
  
  # Private helper functions
  
  # Parse rhythm notation into {base_denomination, dotted?, triplet?}
  defp parse_rhythm("/" <> rest) do
    # Match dotted notation
    {base, dotted} = case String.split(rest, ".", parts: 2) do
      [base, ""] -> {base, true}
      [base] -> {base, false}
    end
    
    # Match triplet notation
    {base, triplet} = case String.split(base, "t", parts: 2) do
      [base, ""] -> {base, true}
      [base] -> {base, false}
    end
    
    # Parse the base denomination
    case Integer.parse(base) do
      {denom, ""} -> {denom, dotted, triplet}
      _ -> nil
    end
  end
  
  defp parse_rhythm(_), do: nil
  
  # Create a cycle of elements to the specified length
  defp cycle(elements, length) do
    Enum.map(0..(length-1), fn i ->
      Enum.at(elements, rem(i, Enum.count(elements)))
    end)
  end
  
  # Calculate least common multiple
  defp lcm(a, b) do
    div(a * b, Integer.gcd(a, b))
  end
end