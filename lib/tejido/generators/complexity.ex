defmodule Tejido.Generators.Complexity do
  @moduledoc """
  Provides methods for generating musical patterns with configurable levels
  of complexity, including melodic and harmonic patterns that can be constrained
  to avoid dissonance.
  """

  alias Tejido.Scales

  @doc """
  Generates a melodic pattern with configurable complexity.

  ## Options
    * `:scale` - The scale to use (e.g. :major, :minor) - defaults to :major
    * `:root` - The root note (e.g. "C") - defaults to "C"
    * `:octave` - The octave to use - defaults to 4
    * `:length` - The number of notes to generate - defaults to 8
    * `:complexity` - A number from 0 to 10 indicating complexity level - defaults to 5
    * `:seed` - Optional seed for random number generation

  Higher complexity levels result in:
  - More varied intervals (larger jumps)
  - More rhythmic variation
  - More syncopation
  - More notes outside the primary scale (passing tones)

  ## Examples
      iex> Tejido.Generators.Complexity.generate_melody(scale: :major, root: "C", complexity: 3)
      "60 62 64 65 - 67 69 72"
  """
  def generate_melody(opts \\ []) do
    scale = Keyword.get(opts, :scale, :major)
    root = Keyword.get(opts, :root, "C")
    octave = Keyword.get(opts, :octave, 4)
    length = Keyword.get(opts, :length, 8)
    complexity = Keyword.get(opts, :complexity, 5) |> normalize_complexity()
    seed = Keyword.get(opts, :seed)

    # Set random seed if provided
    if seed, do: :rand.seed(:exsss, {seed, seed * 2, seed * 3})

    # Generate base scale degrees
    scale_degrees = generate_scale_degrees(complexity, length)
    
    # Convert scale degrees to MIDI notes in the selected scale and key
    scale_tones = scale_degrees
                  |> Enum.map(&to_string/1)
                  |> Enum.join(" ")
                  |> Scales.scale_pattern(scale)
    
    # Convert to actual MIDI notes in the selected key and octave
    midi_notes = Scales.to_midi_pattern(scale_tones, root, octave)
    
    # Apply rhythm variations based on complexity
    apply_rhythm_variations(midi_notes, complexity)
  end

  @doc """
  Generates a bassline pattern that follows harmonic rules and avoids dissonance.

  ## Options
    * `:chord_progression` - A string of chord symbols (e.g. "C Am F G") - defaults to "C F G Am"
    * `:scale` - The scale to use (e.g. :major, :minor) - defaults to :major
    * `:root` - The root note for the scale (e.g. "C") - defaults to "C"
    * `:octave` - The octave to use - defaults to 2 (bass range)
    * `:notes_per_chord` - Number of notes to generate per chord - defaults to 4
    * `:complexity` - A number from 0 to 10 indicating complexity level - defaults to 3
    * `:style` - Bass style (:walking, :arpeggiated, :repeated) - defaults to :walking
    * `:seed` - Optional seed for random number generation

  ## Examples
      iex> Tejido.Generators.Complexity.generate_bassline(chord_progression: "C F G Am", complexity: 2)
      "36 - 36 - 41 - 43 - 43 - 43 - 36 - 40"
  """
  def generate_bassline(opts \\ []) do
    chord_progression = Keyword.get(opts, :chord_progression, "C F G Am")
    scale = Keyword.get(opts, :scale, :major)
    root = Keyword.get(opts, :root, "C")
    octave = Keyword.get(opts, :octave, 2)
    notes_per_chord = Keyword.get(opts, :notes_per_chord, 4)
    complexity = Keyword.get(opts, :complexity, 3) |> normalize_complexity()
    style = Keyword.get(opts, :style, :walking)
    seed = Keyword.get(opts, :seed)

    # Set random seed if provided
    if seed, do: :rand.seed(:exsss, {seed, seed * 2, seed * 3})

    # Parse chord progression
    chords = String.split(chord_progression)
    
    # Generate bass pattern for each chord
    bass_pattern = chords
                   |> Enum.flat_map(fn chord -> 
                        generate_bass_notes_for_chord(chord, style, complexity, notes_per_chord, scale, root, octave)
                      end)
                   |> Enum.join(" ")
    
    # Apply rhythm variations based on complexity
    apply_rhythm_variations(bass_pattern, complexity)
  end
  
  @doc """
  Apply harmonic constraints to a pattern to avoid dissonance against a chord progression.

  ## Options
    * `:chord_progression` - A string of chord symbols (e.g. "C Am F G") - required
    * `:scale` - The scale to use (e.g. :major, :minor) - defaults to :major
    * `:root` - The root note for the scale (e.g. "C") - defaults to "C"
    * `:tension` - A number from 0 to 10 indicating how much tension (dissonance) to allow - defaults to 3
    * `:preserve_rhythm` - Whether to preserve rests and rhythmic elements - defaults to true

  ## Examples
      iex> Tejido.Generators.Complexity.constrain_to_chords("60 62 64 65 67 69 71 72", chord_progression: "C F G")
      "60 64 67 65 67 69 71 72"
  """
  def constrain_to_chords(pattern, opts) do
    chord_progression = Keyword.fetch!(opts, :chord_progression)
    scale = Keyword.get(opts, :scale, :major)
    root = Keyword.get(opts, :root, "C")
    tension = Keyword.get(opts, :tension, 3) |> normalize_complexity()
    preserve_rhythm = Keyword.get(opts, :preserve_rhythm, true)
    
    # Parse chord progression
    chords = String.split(chord_progression)
    
    # Parse pattern
    notes = String.split(pattern)
    
    # Determine how many notes per chord
    notes_per_chord = ceil(length(notes) / length(chords))
    
    # Group notes by chord
    notes_groups = Enum.chunk_every(notes, notes_per_chord)
    
    # Apply harmonic constraints to each group based on its chord
    constrained_groups = Enum.zip(notes_groups, chords)
                         |> Enum.map(fn {notes_group, chord} ->
                              constrain_notes_to_chord(notes_group, chord, scale, root, tension, preserve_rhythm)
                            end)
    
    # Flatten and join the result
    Enum.concat(constrained_groups) |> Enum.join(" ")
  end

  # Generate scale degrees based on complexity level
  defp generate_scale_degrees(complexity, length) do
    # For low complexity, use primarily steps, with occasional small jumps
    # For high complexity, use more varied intervals including larger jumps
    
    # Initialize with the tonic (1)
    degrees = [1]
    
    # Define possible moves based on complexity
    common_moves = [1, 1, 2, 2, -1, -1, -2]
    complex_moves = [3, 4, 5, -3, -4, 6, -5]
    
    # Calculate number of complex moves based on complexity
    complex_ratio = complexity / 10
    
    # Generate the remaining notes
    1..(length - 1)
    |> Enum.reduce(degrees, fn _, acc ->
      current = hd(acc)
      
      # Choose between common and complex moves based on complexity
      move = if :rand.uniform() < complex_ratio do
        Enum.random(complex_moves)
      else
        Enum.random(common_moves)
      end
      
      # Calculate new scale degree, keeping it within a reasonable range (1-15)
      new_degree = current + move
      new_degree = cond do
        new_degree < 1 -> new_degree + 7
        new_degree > 15 -> new_degree - 7
        true -> new_degree
      end
      
      [new_degree | acc]
    end)
    |> Enum.reverse()
  end

  # Apply rhythm variations based on complexity
  defp apply_rhythm_variations(pattern, complexity) do
    # For low complexity, use regular rhythms
    # For high complexity, introduce rests and syncopation
    notes = String.split(pattern)
    
    # Calculate rest probability based on complexity
    rest_probability = complexity * 0.03
    
    # Apply rests based on complexity
    notes
    |> Enum.map(fn note ->
      if :rand.uniform() < rest_probability do
        "-" # Insert a rest
      else
        note
      end
    end)
    |> Enum.join(" ")
  end

  # Generate bass notes for a specific chord based on style and complexity
  defp generate_bass_notes_for_chord(chord, style, complexity, count, scale, root, octave) do
    # Parse chord to get root and type
    {chord_root, chord_type} = parse_chord(chord)
    
    # Get chord tones as MIDI notes
    chord_tones = get_chord_tones(chord_root, chord_type, octave)
    
    # Generate notes based on style
    case style do
      :repeated ->
        # Simple repeated root notes with occasional fifths
        List.duplicate(hd(chord_tones), count)
        
      :arpeggiated ->
        # Arpeggiate through chord tones
        cycle_notes(chord_tones, count)
        
      :walking ->
        # Walking bass with more movement between chord tones
        generate_walking_bass(chord_tones, count, complexity)
        
      _ ->
        # Default to repeated root
        List.duplicate(hd(chord_tones), count)
    end
  end

  # Generate a walking bass line with given chord tones
  defp generate_walking_bass(chord_tones, count, complexity) do
    # Start with root
    bass_line = [hd(chord_tones)]
    
    # Generate remaining notes
    1..(count - 1)
    |> Enum.reduce(bass_line, fn i, acc ->
      current = hd(acc)
      
      # On last beat of the pattern, tend to move to next chord root or fifth
      next = if i == count - 1 do
        if :rand.uniform() < 0.7 do
          # Move to fifth or approach next root
          fifth_idx = min(length(chord_tones) - 1, 2)
          Enum.at(chord_tones, fifth_idx)
        else
          # Stay within chord tones
          Enum.random(chord_tones)
        end
      else
        # Use complexity to determine if we stay on chord tones or use passing tones
        if :rand.uniform() < complexity / 10 do
          # Use passing tones (up to 2 semitones from current or chord tone)
          passing_tone = current + Enum.random([-2, -1, 1, 2])
          # Constrain to reasonable range
          max(current - 5, min(current + 5, passing_tone))
        else
          # Use chord tones
          Enum.random(chord_tones)
        end
      end
      
      [next | acc]
    end)
    |> Enum.reverse()
    |> Enum.map(&to_string/1)
  end

  # Parse a chord symbol into root and type
  defp parse_chord(chord) do
    cond do
      String.match?(chord, ~r/[A-G][#b]?m7/) ->
        {String.replace(chord, "m7", ""), :minor7}
        
      String.match?(chord, ~r/[A-G][#b]?7/) ->
        {String.replace(chord, "7", ""), :dominant7}
        
      String.match?(chord, ~r/[A-G][#b]?maj7/) ->
        {String.replace(chord, "maj7", ""), :major7}
        
      String.match?(chord, ~r/[A-G][#b]?m/) ->
        {String.replace(chord, "m", ""), :minor}
        
      String.match?(chord, ~r/[A-G][#b]?dim/) ->
        {String.replace(chord, "dim", ""), :diminished}
        
      String.match?(chord, ~r/[A-G][#b]?aug/) ->
        {String.replace(chord, "aug", ""), :augmented}
        
      String.match?(chord, ~r/[A-G][#b]?sus/) ->
        {String.replace(chord, "sus", ""), :sus4}
        
      true ->
        {chord, :major}  # Default to major
    end
  end

  # Get chord tones as MIDI notes
  defp get_chord_tones(chord_root, chord_type, octave) do
    # Get chord intervals
    intervals = case chord_type do
      :major -> [0, 4, 7]
      :minor -> [0, 3, 7]
      :dominant7 -> [0, 4, 7, 10]
      :major7 -> [0, 4, 7, 11]
      :minor7 -> [0, 3, 7, 10]
      :diminished -> [0, 3, 6]
      :augmented -> [0, 4, 8]
      :sus4 -> [0, 5, 7]
      _ -> [0, 4, 7]  # Default to major
    end
    
    # Calculate root MIDI note
    root_midi = case chord_root do
      "C" -> 0
      "C#" -> 1
      "Db" -> 1
      "D" -> 2
      "D#" -> 3
      "Eb" -> 3
      "E" -> 4
      "F" -> 5
      "F#" -> 6
      "Gb" -> 6
      "G" -> 7
      "G#" -> 8
      "Ab" -> 8
      "A" -> 9
      "A#" -> 10
      "Bb" -> 10
      "B" -> 11
      _ -> 0  # Default to C
    end
    
    # Calculate MIDI notes
    base = (octave + 1) * 12 + root_midi
    Enum.map(intervals, fn interval -> base + interval end)
  end

  # Cycle through a list repeatedly until reaching count items
  defp cycle_notes(notes, count) do
    Stream.cycle(notes)
    |> Enum.take(count)
    |> Enum.map(&to_string/1)
  end

  # Constrain notes to a chord
  defp constrain_notes_to_chord(notes, chord, scale, root, tension, preserve_rhythm) do
    {chord_root, chord_type} = parse_chord(chord)
    
    # Get chord tones
    intervals = case chord_type do
      :major -> [0, 4, 7]
      :minor -> [0, 3, 7]
      :dominant7 -> [0, 4, 7, 10]
      :major7 -> [0, 4, 7, 11]
      :minor7 -> [0, 3, 7, 10]
      :diminished -> [0, 3, 6]
      :augmented -> [0, 4, 8]
      :sus4 -> [0, 5, 7]
      _ -> [0, 4, 7]  # Default to major
    end
    
    # Calculate permitted notes based on tension level
    permitted_intervals = if tension > 5 do
      # With high tension, allow some non-chord tones
      intervals ++ case chord_type do
        :major -> [2, 9, 5]  # 2nd, 6th, 4th
        :minor -> [2, 5, 9]  # 2nd, 4th, 6th
        _ -> [2, 5, 9]
      end
    else
      # With low tension, stricter adherence to chord tones
      intervals
    end
    
    # Convert chord root to numeric value
    root_value = case chord_root do
      "C" -> 0
      "C#" -> 1
      "Db" -> 1
      "D" -> 2
      "D#" -> 3
      "Eb" -> 3
      "E" -> 4
      "F" -> 5
      "F#" -> 6
      "Gb" -> 6
      "G" -> 7
      "G#" -> 8
      "Ab" -> 8
      "A" -> 9
      "A#" -> 10
      "Bb" -> 10
      "B" -> 11
      _ -> 0  # Default to C
    end
    
    # Map each note to a permitted chord tone
    notes
    |> Enum.map(fn note ->
      if preserve_rhythm && note == "-" do
        "-"  # Keep rests
      else
        case Integer.parse(note) do
          {midi_note, ""} ->
            # Calculate note position relative to chord root
            note_value = rem(midi_note, 12)
            octave = div(midi_note, 12)
            
            # Find distance from chord root
            distance = rem(note_value - root_value + 12, 12)
            
            # Find closest permitted interval
            closest_interval = Enum.min_by(permitted_intervals, fn interval ->
              abs(rem(interval - distance + 12, 12))
            end)
            
            # Calculate new note
            new_base = root_value + rem(closest_interval, 12)
            new_midi = octave * 12 + new_base
            
            to_string(new_midi)
            
          _ ->
            note  # Keep non-numeric values
        end
      end
    end)
  end

  # Ensure complexity is within 0-10 range
  defp normalize_complexity(complexity) do
    cond do
      complexity < 0 -> 0
      complexity > 10 -> 10
      true -> complexity
    end
  end
end