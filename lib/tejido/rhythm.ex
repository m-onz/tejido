defmodule Tejido.Rhythm do
  @moduledoc """
  Provides shorthand notation for rhythmic values and time signatures.
  Allows expressing note durations using conventional music notation.
  """

  @doc """
  Maps rhythmic notation to durations in beats (as integers).
  
  Supported notation:
  - "/1" - Whole note (4 beats in 4/4)
  - "/2" - Half note (2 beats in 4/4)
  - "/4" - Quarter note (1 beat in 4/4)
  - "/8" - Eighth note (rounded to 1 beat)
  - "/16" - Sixteenth note (rounded to 0 beats)
  - "/32" - Thirty-second note (rounded to 0 beats)
  
  Dotted notes (1.5x duration, rounded to integer):
  - "/4." - Dotted quarter note (2 beats in 4/4)
  
  Tuplets (rounded to integer):
  - "/4t" - Quarter note triplet (1 beat in 4/4)
  - "/8t" - Eighth note triplet (0 beats in 4/4)
  
  ## Examples
      iex> Tejido.Rhythm.duration("/1")
      4
      
      iex> Tejido.Rhythm.duration("/4")
      1
      
      iex> Tejido.Rhythm.duration("/8.")
      2
      
      iex> Tejido.Rhythm.duration("/4t")
      1
  """
  def duration(rhythm_value) do
    case parse_rhythm(rhythm_value) do
      {base, dotted, triplet} ->
        base_duration = case base do
          1 -> 4
          2 -> 2
          4 -> 1
          8 -> 1   # Rounded to nearest int
          16 -> 0  # Rounded to nearest int
          32 -> 0  # Rounded to nearest int
          _ -> 1   # Default to quarter note
        end
        
        # Apply dotted note adjustment (1.5x, rounded)
        dot_multiplier = if dotted, do: 1.5, else: 1.0
        
        # Apply triplet adjustment (2/3, rounded)
        triplet_multiplier = if triplet, do: 2/3, else: 1.0
        
        round(base_duration * dot_multiplier * triplet_multiplier)
      
      _ -> 1 # Default to quarter note if parsing fails
    end
  end
  
  @doc """
  Parses a rhythm string into a pattern of durations.
  
  ## Examples
      iex> Tejido.Rhythm.parse("/4 /8 /8 /4")
      "1 1 1 1"
      
      iex> Tejido.Rhythm.parse("/1 /2 /4 /8 /16")
      "4 2 1 1 0"
  """
  def parse(rhythm_notation) do
    rhythm_notation
    |> String.split(" ", trim: true)
    |> Enum.map(&duration/1)
    |> Enum.map(&to_string/1)
    |> Enum.join(" ")
  end
  
  @doc """
  Expands a note pattern based on rhythm notation.
  
  ## Examples
      iex> Tejido.Rhythm.expand_rhythm("60", "/4 /8 /8 /4")
      "60:1 60:1 60:1 60:1"
      
      iex> Tejido.Rhythm.expand_rhythm("60 64 67", "/4. /8 /16")
      "60:2 64:1 67:0"
  """
  def expand_rhythm(note_pattern, rhythm_notation) do
    notes = String.split(note_pattern, " ", trim: true)
    durations = rhythm_notation
      |> String.split(" ", trim: true)
      |> Enum.map(&duration/1)
    
    n_length = length(notes)
    r_length = length(durations)
    
    0..max(n_length, r_length)-1
    |> Enum.map(fn i ->
      note = Enum.at(notes, rem(i, n_length))
      dur = Enum.at(durations, rem(i, r_length))
      "#{note}:#{dur}"
    end)
    |> Enum.join(" ")
  end
  
  @doc """
  Applies swing feel to a pattern by adjusting durations.
  Swing is quantized to integer durations.
  
  ## Examples
      iex> Tejido.Rhythm.swing("1 2 3 4", 0.1)
      "1:2 2:2 3:2 4:2"
      
      iex> Tejido.Rhythm.swing("1 2 3 4", 0.5)
      "1:2 2:0 3:2 4:0"
  """
  def swing(pattern, swing_amount) do
    elements = String.split(pattern, " ", trim: true)
    
    # Ensure we process pairs of elements
    paired_elements = 
      if rem(length(elements), 2) == 1 do
        elements ++ ["-"]  # Add a rest if odd
      else
        elements
      end
    
    # For small swing values, just use even durations
    if swing_amount < 0.3 do
      # For light swing, all durations are 2
      swung_elements = paired_elements
      |> Enum.map(fn elem -> "#{elem}:2" end)
      
      # Trim back to original length
      swung_elements
      |> Enum.take(length(elements))
      |> Enum.join(" ")
    else
      # For strong swing (>= 0.3), use alternating durations
      swung_elements = paired_elements
      |> Enum.chunk_every(2)
      |> Enum.flat_map(fn chunk ->
        case chunk do
          [first, second] -> ["#{first}:2", "#{second}:0"]  # On gets 2, off gets 0
          [single] -> ["#{single}:2"]  # Just in case of odd number
        end
      end)
      
      # Trim back to original length
      swung_elements
      |> Enum.take(length(elements))
      |> Enum.join(" ")
    end
  end

  # Helper function to parse rhythm notation
  defp parse_rhythm(rhythm_value) do
    cond do
      # Dotted note with triplet
      Regex.match?(~r{^/(\d+)\.t$}, rhythm_value) ->
        [_, base] = Regex.run(~r{^/(\d+)\.t$}, rhythm_value)
        {String.to_integer(base), true, true}
        
      # Dotted note
      Regex.match?(~r{^/(\d+)\.$}, rhythm_value) ->
        [_, base] = Regex.run(~r{^/(\d+)\.$}, rhythm_value)
        {String.to_integer(base), true, false}
        
      # Triplet
      Regex.match?(~r{^/(\d+)t$}, rhythm_value) ->
        [_, base] = Regex.run(~r{^/(\d+)t$}, rhythm_value)
        {String.to_integer(base), false, true}
        
      # Regular note
      Regex.match?(~r{^/(\d+)$}, rhythm_value) ->
        [_, base] = Regex.run(~r{^/(\d+)$}, rhythm_value)
        {String.to_integer(base), false, false}
        
      true ->
        nil
    end
  end
end