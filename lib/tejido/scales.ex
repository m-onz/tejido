defmodule Tejido.Scales do
  @moduledoc """
  Provides musical scale and chord definitions for Tejido.
  Enables conversion between scale degrees, note names, and MIDI values.
  """

  @scales %{
    major: [0, 2, 4, 5, 7, 9, 11],
    minor: [0, 2, 3, 5, 7, 8, 10],
    dorian: [0, 2, 3, 5, 7, 9, 10],
    phrygian: [0, 1, 3, 5, 7, 8, 10],
    lydian: [0, 2, 4, 6, 7, 9, 11],
    mixolydian: [0, 2, 4, 5, 7, 9, 10],
    locrian: [0, 1, 3, 5, 6, 8, 10],
    harmonic_minor: [0, 2, 3, 5, 7, 8, 11],
    melodic_minor: [0, 2, 3, 5, 7, 9, 11],
    chromatic: Enum.to_list(0..11),
    pentatonic_major: [0, 2, 4, 7, 9],
    pentatonic_minor: [0, 3, 5, 7, 10],
    blues: [0, 3, 5, 6, 7, 10]
  }

  @chords %{
    major: [0, 4, 7],
    minor: [0, 3, 7],
    diminished: [0, 3, 6],
    augmented: [0, 4, 8],
    sus2: [0, 2, 7],
    sus4: [0, 5, 7],
    major7: [0, 4, 7, 11],
    minor7: [0, 3, 7, 10],
    dominant7: [0, 4, 7, 10],
    diminished7: [0, 3, 6, 9],
    half_diminished7: [0, 3, 6, 10],
    augmented7: [0, 4, 8, 10]
  }

  @note_names ~w(C C# D D# E F F# G G# A A# B)
  @note_name_to_semitone Enum.with_index(@note_names) |> Enum.into(%{})

  @doc """
  Lists all available scales.
  """
  def list_scales, do: Map.keys(@scales)

  @doc """
  Lists all available chord types.
  """
  def list_chords, do: Map.keys(@chords)
  
  @doc """
  Gets the list of semitone offsets in a scale.
  
  ## Examples
      iex> Tejido.Scales.scale_degrees(:major)
      [0, 2, 4, 5, 7, 9, 11]
      
      iex> Tejido.Scales.scale_degrees(:minor)
      [0, 2, 3, 5, 7, 8, 10]
  """
  def scale_degrees(scale_type) do
    Map.get(@scales, scale_type, @scales.chromatic)
  end
  
  @doc """
  Gets the list of semitone offsets in a chord.
  
  ## Examples
      iex> Tejido.Scales.chord_intervals(:major)
      [0, 4, 7]
      
      iex> Tejido.Scales.chord_intervals(:dominant7)
      [0, 4, 7, 10]
  """
  def chord_intervals(chord_type) do
    Map.get(@chords, chord_type, @chords.major)
  end
  
  @doc """
  Converts a note name (without octave) to its semitone offset.
  
  ## Examples
      iex> Tejido.Scales.note_name_to_semitone("C")
      0
      
      iex> Tejido.Scales.note_name_to_semitone("F#")
      6
  """
  def note_name_to_semitone(note_name) do
    Map.get(@note_name_to_semitone, note_name, 0)
  end

  @doc """
  Converts a scale degree to a semitone offset within a scale.
  
  ## Examples
      iex> Tejido.Scales.degree_to_semitone(1, :major)
      0
      
      iex> Tejido.Scales.degree_to_semitone(5, :major)
      7
  """
  def degree_to_semitone(degree, scale) when is_integer(degree) and degree > 0 do
    scale_steps = Map.get(@scales, scale, @scales.chromatic)
    octave = div(degree - 1, length(scale_steps))
    degree_in_octave = rem(degree - 1, length(scale_steps))
    
    octave * 12 + Enum.at(scale_steps, degree_in_octave, 0)
  end

  @doc """
  Maps a pattern of scale degrees to semitones within a scale.
  
  ## Examples
      iex> Tejido.Scales.scale_pattern("1 3 5", :major)
      "0 4 7"
      
      iex> Tejido.Scales.scale_pattern("1 2 3 4 5", :pentatonic_minor)
      "0 3 5 7 10"
  """
  def scale_pattern(pattern, scale) do
    Tejido.transform(pattern, fn note ->
      case note do
        "-" -> "-"  # Preserve rests
        n ->
          case Integer.parse(n) do
            {degree, ""} -> 
              degree_to_semitone(degree, scale) |> to_string()
            _ -> note  # Pass through non-numeric values
          end
      end
    end)
  end

  @doc """
  Converts a semitone value to a MIDI note value in a specific key.
  
  ## Examples
      iex> Tejido.Scales.to_midi_note(0, "C", 4)
      60
      
      iex> Tejido.Scales.to_midi_note(4, "G", 3)
      59
  """
  def to_midi_note(semitone, key, octave \\ 4) do
    key_offset = Map.get(@note_name_to_semitone, key, 0)
    octave * 12 + key_offset + semitone
  end

  @doc """
  Maps a pattern of semitones to MIDI notes in a specific key and octave.
  
  ## Examples
      iex> Tejido.Scales.to_midi_pattern("0 4 7", "C", 4)
      "60 64 67"
      
      iex> Tejido.Scales.to_midi_pattern("0 3 7", "F", 3)
      "53 56 60"
  """
  def to_midi_pattern(pattern, key, octave \\ 4) do
    Tejido.transform(pattern, fn note ->
      case note do
        "-" -> "-"  # Preserve rests
        n ->
          case Integer.parse(n) do
            {semitone, ""} -> 
              to_midi_note(semitone, key, octave) |> to_string()
            _ -> note  # Pass through non-numeric values
          end
      end
    end)
  end

  @doc """
  Generates a chord pattern from a chord symbol and type.
  
  ## Examples
      iex> Tejido.Scales.chord(:major, "C")
      "0 4 7"
      
      iex> Tejido.Scales.chord(:minor7, "A")
      "0 3 7 10"
  """
  def chord(chord_type, _root \\ "C") do
    chord_steps = Map.get(@chords, chord_type, @chords.major)
    Enum.join(chord_steps, " ")
  end

  @doc """
  Maps a chord progression in roman numerals to semitones in a scale.
  
  ## Examples
      iex> Tejido.Scales.parse_chords("I IV V", :major, "C")
      "0 4 7 5 9 12 7 11 14"
      
      iex> Tejido.Scales.parse_chords("i iv v", :minor, "A")
      "0 3 7 5 8 12 7 10 14"
  """
  def parse_chords(progression, scale, _root \\ "C") do
    # Use the scale information when parsing chord symbols
    progression
    |> String.split(" ", trim: true)
    |> Enum.map(fn chord_symbol ->
      {degree, chord_type} = parse_chord_symbol(chord_symbol, scale)
      degree_semitone = degree_to_semitone(degree, scale)
      
      # Get chord intervals
      chord_intervals = Map.get(@chords, chord_type, @chords.major)
      
      # Build the chord starting from the appropriate scale degree
      Enum.map(chord_intervals, fn interval -> 
        degree_semitone + interval
      end)
    end)
    |> List.flatten()
    |> Enum.join(" ")
  end

  # Parse roman numeral chord symbols
  defp parse_chord_symbol(symbol, scale) do
    {degree, modifier} = case String.downcase(symbol) do
      "i" -> {1, if(symbol == "I", do: :major, else: :minor)}
      "ii" -> {2, if(symbol == "II", do: :major, else: :minor)}
      "iii" -> {3, if(symbol == "III", do: :major, else: :minor)}
      "iv" -> {4, if(symbol == "IV", do: :major, else: :minor)}
      "v" -> {5, if(symbol == "V", do: :major, else: :minor)}
      "vi" -> {6, if(symbol == "VI", do: :major, else: :minor)}
      "vii" -> {7, if(symbol == "VII", do: :major, else: :minor)}
      _ -> {1, :major}  # Default to I if not recognized
    end
    
    # Override modifier based on scale if not explicitly set by case
    modifier = if scale == :minor and symbol == String.downcase(symbol), do: :minor, else: modifier
    
    {degree, modifier}
  end

  @doc """
  Converts a note name to a MIDI note value.
  
  ## Examples
      iex> Tejido.Scales.note_to_midi("C4")
      60
      
      iex> Tejido.Scales.note_to_midi("F#3")
      54
  """
  def note_to_midi(note_name) do
    {note, octave} = parse_note_name(note_name)
    semitone = Map.get(@note_name_to_semitone, note, 0)
    # Adjust for MIDI octave convention (C4 = 60)
    (octave + 1) * 12 + semitone
  end

  @doc """
  Converts a MIDI note value to a note name.
  
  ## Examples
      iex> Tejido.Scales.midi_to_note(60)
      "C4"
      
      iex> Tejido.Scales.midi_to_note(66)
      "F#4"
  """
  def midi_to_note(midi) do
    # Adjust for MIDI octave convention (C4 = 60, so 60 // 12 - 1 = 4)
    octave = div(midi, 12) - 1
    note_index = rem(midi, 12)
    note = Enum.at(@note_names, note_index)
    "#{note}#{octave}"
  end

  @doc """
  Converts a pattern of note names to MIDI values.
  
  ## Examples
      iex> Tejido.Scales.notes_to_midi("C4 E4 G4")
      "60 64 67"
      
      iex> Tejido.Scales.notes_to_midi("F3 - A3")
      "53 - 57"
  """
  def notes_to_midi(pattern) do
    pattern
    |> String.split(" ", trim: true)
    |> Enum.map(fn note ->
      case note do
        "-" -> "-"  # Preserve rests
        _ -> 
          try do
            note_to_midi(note) |> to_string()
          rescue
            _ -> note  # If parsing fails, keep original note
          end
      end
    end)
    |> Enum.join(" ")
  end

  @doc """
  Converts a pattern of MIDI values to note names.
  
  ## Examples
      iex> Tejido.Scales.midi_to_notes("60 64 67")
      "C4 E4 G4"
      
      iex> Tejido.Scales.midi_to_notes("53 - 57")
      "F3 - A3"
  """
  def midi_to_notes(pattern) do
    pattern
    |> String.split(" ", trim: true)
    |> Enum.map(fn note ->
      case note do
        "-" -> "-"  # Preserve rests
        _ -> 
          case Integer.parse(note) do
            {midi, ""} -> midi_to_note(midi)
            _ -> note  # Pass through non-numeric values
          end
      end
    end)
    |> Enum.join(" ")
  end

  # Parses a note name into note and octave
  defp parse_note_name(note_name) do
    # Match patterns like "C4", "F#3", etc.
    case Regex.run(~r/([A-G][#b]?)(\d+)/, note_name) do
      [_, note, octave] -> {note, String.to_integer(octave)}
      _ -> {"C", 4}  # Default if format isn't recognized
    end
  end
end