defmodule Tejido.Generators.Melody do
  @moduledoc """
  Specialized pattern generator for creating melodic patterns with configurable
  complexity parameters. Provides functions for generating melodies with control over
  specific musical characteristics like intervals, contour, and rhythmic density.
  
  All patterns are generated in the standard Tejido format of integers and hyphens,
  which can be transformed by other Tejido modules like Tejido.Rhythm for swing
  and other timing manipulations.
  """

  alias Tejido.Scales
  alias Tejido.Rhythm

  @doc """
  Generates a melodic pattern with highly configurable parameters.

  ## Options
    * `:scale` - The scale to use (e.g. :major, :minor) - defaults to :major
    * `:root` - The root note (e.g. "C") - defaults to "C"
    * `:octave` - The octave to use - defaults to 4
    * `:length` - The number of notes to generate - defaults to 8
    * `:seed` - Optional seed for random number generation
    * `:contour` - Shape of the melody (:ascending, :descending, :arch, :valley, :random) - defaults to :random
    * `:interval_complexity` - Value from 0-10 controlling the size of intervals - defaults to 5
    * `:rhythm_complexity` - Value from 0-10 controlling rhythmic variation - defaults to 5 
    * `:consonance` - Value from 0-10 controlling preference for consonant intervals - defaults to 5
    * `:repetition` - Value from 0-10 controlling note repetition frequency - defaults to 5
    * `:syncopation` - Value from 0-10 controlling syncopation level - defaults to 5
    * `:chord_notes` - List of chord notes to emphasize (scale degrees) - defaults to [1, 3, 5]
    * `:range_constraint` - Tuple {min, max} to constrain range - defaults to {-7, 7} semitones from root

  Returns a pattern string consisting of only integers and hyphens.

  ## Examples
      # Output varies due to randomization, but will be integers and hyphens
      iex> pattern = Tejido.Generators.Melody.generate(scale: :major)
      iex> String.split(pattern, " ") |> Enum.all?(fn note -> note == "-" || Integer.parse(note) != :error end)
      true
  """
  def generate(opts \\ []) do
    # Extract options
    scale = Keyword.get(opts, :scale, :major)
    root = Keyword.get(opts, :root, "C")
    octave = Keyword.get(opts, :octave, 4)
    length = Keyword.get(opts, :length, 8)
    seed = Keyword.get(opts, :seed)
    contour = Keyword.get(opts, :contour, :random)
    interval_complexity = normalize_value(Keyword.get(opts, :interval_complexity, 5))
    rhythm_complexity = normalize_value(Keyword.get(opts, :rhythm_complexity, 5))
    consonance = normalize_value(Keyword.get(opts, :consonance, 5))
    repetition = normalize_value(Keyword.get(opts, :repetition, 5))
    syncopation = normalize_value(Keyword.get(opts, :syncopation, 5))
    chord_notes = Keyword.get(opts, :chord_notes, [1, 3, 5])
    range_constraint = Keyword.get(opts, :range_constraint, {-7, 7})

    # Set random seed if provided
    if seed, do: :rand.seed(:exsss, {seed, seed * 2, seed * 3})

    # Get the scale degrees
    scale_intervals = Scales.scale_degrees(scale)
    scale_size = length(scale_intervals)

    # Generate the melodic shape according to the contour
    degrees = generate_contour(contour, length, scale_size)

    # Apply interval complexity
    degrees = apply_interval_complexity(degrees, interval_complexity, scale_size, range_constraint)

    # Apply repetition preference
    degrees = apply_repetition(degrees, repetition)
    
    # Apply consonance preference (emphasize chord notes)
    degrees = apply_consonance(degrees, consonance, chord_notes, scale_size)

    # Convert scale degrees to MIDI notes
    scale_tones = degrees
                  |> Enum.map(&to_string/1)
                  |> Enum.join(" ")
                  |> Scales.scale_pattern(scale)
    
    # Convert to actual MIDI notes in the selected key and octave
    midi_notes = Scales.to_midi_pattern(scale_tones, root, octave)
    
    # Apply rhythm variations based on complexity and syncopation
    rhythm_pattern = apply_rhythm_variations(midi_notes, rhythm_complexity, syncopation)
    
    # Ensure output only contains hyphens and integer numbers
    rhythm_pattern
    |> String.split(" ")
    |> Enum.map(fn
      "-" -> "-"
      note -> 
        case Integer.parse(note) do
          {num, ""} -> Integer.to_string(num)
          _ -> "-" # Replace any non-integer with a hyphen
        end
    end)
    |> Enum.join(" ")
  end

  @doc """
  Transforms a melodic pattern by applying various development techniques.

  ## Options
    * `:technique` - The transformation technique to apply (:inversion, :retrograde, :augmentation,
                    :diminution, :sequence, :fragmentation, :development) - defaults to :development
    * `:amount` - How strongly to apply the technique (for applicable techniques) - defaults to 5 (range 0-10)
    * Other options passed to the specific technique implementation

  ## Examples
      iex> pattern = "60 62 64 67 69"
      iex> Tejido.Generators.Melody.develop(pattern, technique: :inversion)
      "60 58 56 53 51"

      iex> pattern = "60 62 64 67 69"
      iex> Tejido.Generators.Melody.develop(pattern, technique: :sequence, interval: 3)
      "60 62 64 67 69 63 65 67 70 72"
  """
  def develop(pattern, opts \\ []) do
    technique = Keyword.get(opts, :technique, :development)
    amount = normalize_value(Keyword.get(opts, :amount, 5))
    
    # Parse the pattern to MIDI notes for manipulation
    # Ensure we only work with integers and hyphens from the start
    notes = pattern
            |> String.split(" ", trim: true)
            |> Enum.map(fn note ->
                case note do
                  "-" -> nil  # Mark rests as nil
                  n -> case Integer.parse(n) do
                    {num, ""} -> num
                    _ -> nil  # Mark non-integers as nil
                  end
                end
            end)
    
    # Apply the chosen technique
    transformed_notes = case technique do
      :inversion -> invert_melody(notes, opts)
      :retrograde -> retrograde_melody(notes, opts)
      :augmentation -> augment_melody(notes, amount, opts)
      :diminution -> diminish_melody(notes, amount, opts)
      :sequence -> sequence_melody(notes, opts)
      :fragmentation -> fragment_melody(notes, amount, opts)
      :development -> develop_melody(notes, amount, opts)
      _ -> notes  # Default just return the original
    end
    
    # Convert back to string format, ensuring only integers and hyphens
    transformed_notes
    |> Enum.map(fn
      nil -> "-"  # Convert nil back to rest
      n -> 
        # Ensure it's an integer
        case is_integer(n) do
          true -> Integer.to_string(n)
          false -> "-" # Replace any non-integer with a hyphen
        end
    end)
    |> Enum.join(" ")
  end

  # Private implementation functions

  # Generate a melodic contour based on the specified shape
  defp generate_contour(contour, length, scale_size) do
    case contour do
      :ascending ->
        # Gradually rising melody
        Enum.map(0..(length - 1), fn i -> 1 + div(i * scale_size, length) end)
        
      :descending ->
        # Gradually falling melody
        Enum.map(0..(length - 1), fn i -> 1 + scale_size - div(i * scale_size, length) end)
        
      :arch ->
        # Rises then falls (arch shape)
        half = div(length, 2)
        rise = Enum.map(0..(half - 1), fn i -> 1 + div(i * scale_size, half) end)
        fall = Enum.map(0..(length - half - 1), fn i -> 1 + scale_size - div(i * scale_size, length - half) end)
        rise ++ fall
        
      :valley ->
        # Falls then rises (valley shape)
        half = div(length, 2)
        fall = Enum.map(0..(half - 1), fn i -> 1 + scale_size - div(i * scale_size, half) end)
        rise = Enum.map(0..(length - half - 1), fn i -> 1 + div(i * scale_size, length - half) end)
        fall ++ rise
        
      :random ->
        # Random walk with small steps
        # Start at the tonic
        degrees = [1]
        
        # Add subsequent notes through a random walk
        1..(length - 1)
        |> Enum.reduce(degrees, fn _, acc ->
          current = hd(acc)
          # Small random movement
          step = Enum.random([-2, -1, 1, 2])
          new_degree = max(1, min(scale_size * 2, current + step))
          [new_degree | acc]
        end)
        |> Enum.reverse()
        
      _ ->
        # Default to a simple scale
        Enum.map(1..length, fn i -> 1 + rem(i - 1, scale_size) end)
    end
  end

  # Apply interval complexity to a series of scale degrees
  defp apply_interval_complexity(degrees, complexity, scale_size, {min_range, max_range}) do
    # Determine how often to add larger intervals
    large_interval_probability = complexity / 15.0
    
    # Normalize to ensure we start with the first degree
    [_first_note | rest] = degrees
    first_normalized = 1
    
    # Apply interval adjustments
    [first_normalized | rest]
    |> Enum.scan(fn degree, prev_degree ->
      if :rand.uniform() < large_interval_probability do
        # Apply a larger interval (between 2-5 scale degrees)
        interval = Enum.random(2..5) * Enum.random([1, -1])
        # Calculate new degree with larger jump, but stay in scale
        new_degree = prev_degree + interval
        # Keep within scale size multiplied by 2 to allow for octave movement
        max(1, min(scale_size * 2, new_degree))
      else
        # Use the original degree from the contour
        degree
      end
    end)
    |> constrain_range(min_range, max_range)
  end

  # Apply repetition preference
  defp apply_repetition(degrees, repetition) do
    # Higher repetition value means more repeated notes
    # Convert to a probability of repeating previous note (0-40%)
    repetition_probability = repetition / 25.0
    
    [first | rest] = degrees
    
    # Process the sequence
    rest
    |> Enum.scan(first, fn degree, prev_degree ->
      if :rand.uniform() < repetition_probability do
        # Repeat the previous note
        prev_degree
      else
        # Use the original degree
        degree
      end
    end)
  end

  # Apply consonance preference (emphasize chord notes)
  defp apply_consonance(degrees, consonance, chord_notes, scale_size) do
    # Higher consonance means higher probability of moving to chord tones
    # Convert to probability (0-70%)
    chord_note_probability = consonance / 15.0
    
    degrees
    |> Enum.map(fn degree ->
      if :rand.uniform() < chord_note_probability do
        # Move to a nearby chord tone
        base_degree = rem(degree - 1, scale_size) + 1
        
        # Find the closest chord tone
        closest_chord_tone = Enum.min_by(chord_notes, fn chord_tone -> 
          abs(base_degree - chord_tone)
        end)
        
        # Adjust octave to match original degree's octave
        octave_shift = div(degree - 1, scale_size) * scale_size
        closest_chord_tone + octave_shift
      else
        # Keep the original degree
        degree
      end
    end)
  end

  # Constrain the melodic range
  defp constrain_range(degrees, min_range, max_range) do
    avg = div(Enum.sum(degrees), length(degrees))
    
    degrees
    |> Enum.map(fn degree ->
      offset = degree - avg
      cond do
        offset < min_range -> avg + min_range
        offset > max_range -> avg + max_range
        true -> degree
      end
    end)
  end

  # Apply rhythm variations based on complexity and syncopation
  defp apply_rhythm_variations(pattern, rhythm_complexity, syncopation) do
    notes = String.split(pattern)
    
    # Calculate probabilities based on complexity settings
    rest_probability = rhythm_complexity * 0.03
    syncopation_probability = syncopation * 0.04
    
    # Apply rests and syncopation
    notes
    |> Enum.with_index()
    |> Enum.map(fn {note, idx} ->
      cond do
        # Add rest based on rhythm complexity
        :rand.uniform() < rest_probability ->
          "-" # Insert a rest
        
        # Add syncopation (shift notes by removing beats on strong positions)
        syncopation > 3 && rem(idx, 4) == 0 && :rand.uniform() < syncopation_probability ->
          "-" # Create syncopation by removing notes on strong beats
          
        true ->
          note
      end
    end)
    |> Enum.join(" ")
  end

  # Invert a melody (mirror the intervals)
  defp invert_melody(notes, opts) do
    # Optional pivot note (defaults to first note)
    pivot_idx = Keyword.get(opts, :pivot_index, 0)
    pivot_note = Enum.at(notes, pivot_idx)
    
    # Skip nil values (rests)
    notes
    |> Enum.map(fn note ->
      case note do
        nil -> nil  # Keep rests
        n -> 
          # Mirror the note around the pivot
          pivot_note + (pivot_note - n)
      end
    end)
  end

  # Retrograde a melody (play it backwards)
  defp retrograde_melody(notes, _opts) do
    Enum.reverse(notes)
  end

  # Augment a melody (stretch rhythm)
  defp augment_melody(notes, amount, _opts) do
    # Amount controls how much augmentation (doubling, tripling, etc.)
    augmentation_factor = max(2, round(amount / 2))
    
    notes
    |> Enum.flat_map(fn note ->
      List.duplicate(note, augmentation_factor)
    end)
  end

  # Diminish a melody (compress rhythm)
  defp diminish_melody(notes, amount, _opts) do
    # Amount controls how much to remove
    keep_probability = max(0.3, 1.0 - (amount / 10))
    
    notes
    |> Enum.filter(fn _ -> :rand.uniform() < keep_probability end)
  end

  # Create a sequence (repeat at higher/lower intervals)
  defp sequence_melody(notes, opts) do
    # How many sequences
    count = Keyword.get(opts, :count, 2)
    # Interval change between sequences
    interval = Keyword.get(opts, :interval, 2)
    
    0..(count-1)
    |> Enum.flat_map(fn i ->
      Enum.map(notes, fn
        nil -> nil  # Keep rest
        note -> note + (i * interval)
      end)
    end)
  end

  # Fragment a melody (break into smaller repeating pieces)
  defp fragment_melody(notes, amount, _opts) do
    # Amount controls fragment size (smaller fragments for higher amounts)
    fragment_size = max(2, round(10 - amount/2))
    
    # Handle empty or invalid input
    if Enum.empty?(notes) || Enum.all?(notes, &is_nil/1) do
      []
    else
      # Remove nil values before chunking to avoid problems
      valid_notes = Enum.reject(notes, &is_nil/1)
      
      valid_notes
      |> Enum.chunk_every(fragment_size, fragment_size, :discard)
      |> Enum.flat_map(fn fragment -> 
        # Repeat each fragment based on its position
        repeat_count = Enum.random(1..2)
        List.duplicate(fragment, repeat_count)
      end)
      |> List.flatten()
    end
  end

  # Develop a melody (combine multiple techniques)
  defp develop_melody(notes, amount, opts) do
    # Handle empty or invalid input
    if Enum.empty?(notes) || Enum.all?(notes, &is_nil/1) do
      []
    else
      # Choose random techniques based on amount
      technique_count = 1 + round(amount / 3)
      
      # Available techniques to combine
      techniques = [:inversion, :retrograde, :sequence] # Exclude fragmentation if causing issues
      
      # Select random techniques
      selected_techniques = 1..technique_count
      |> Enum.map(fn _ -> Enum.random(techniques) end)
      
      # Apply each technique in sequence
      Enum.reduce(selected_techniques, notes, fn technique, acc ->
        case technique do
          :inversion -> invert_melody(acc, opts)
          :retrograde -> retrograde_melody(acc, opts)
          :fragmentation -> fragment_melody(acc, round(amount / 2), opts)
          :sequence -> sequence_melody(acc, [interval: 2, count: 2])
        end
      end)
    end
  end

  # Ensure a value is in the 0-10 range
  defp normalize_value(value) do
    cond do
      value < 0 -> 0
      value > 10 -> 10
      true -> value
    end
  end
  
  @doc """
  Generates a melodic pattern with swing feel.
  
  Takes the same parameters as `generate/1` plus:
  
  ## Swing Options
    * `:swing` - Value from 0-1 controlling swing amount - defaults to 0.5
    
  Returns a pattern with note:duration format for use with sequencers.
    
  ## Examples
      # Output is in format "note:duration" with alternating 2:0 durations for strong swing
      iex> melody = Tejido.Generators.Melody.swing_melody(swing: 0.5)
      iex> String.split(melody, " ") |> Enum.all?(fn part -> String.contains?(part, ":") end)
      true
  """
  def swing_melody(opts \\ []) do
    # Extract swing parameter and remove it from options
    swing = Keyword.get(opts, :swing, 0.5)
    melody_opts = Keyword.delete(opts, :swing)
    
    # Generate basic melody pattern
    melody_pattern = generate(melody_opts)
    
    # Apply swing using Tejido.Rhythm
    Rhythm.swing(melody_pattern, swing)
  end
  
  @doc """
  Transforms a pattern to include rhythm durations.
  
  ## Examples
      iex> pattern = Tejido.Generators.Melody.with_rhythm("60 64 67", "/4 /8 /8")
      iex> String.split(pattern, " ") |> Enum.all?(fn part -> String.contains?(part, ":") end)
      true
  """
  def with_rhythm(pattern, rhythm_notation) do
    Rhythm.expand_rhythm(pattern, rhythm_notation)
  end
end