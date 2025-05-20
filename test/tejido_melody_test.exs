defmodule TejidoMelodyTest do
  use ExUnit.Case
  alias Tejido.Generators.Melody
  doctest Tejido.Generators.Melody

  test "generates a basic melody with default options" do
    melody = Melody.generate(seed: 42)
    assert is_binary(melody)
    assert String.contains?(melody, " ")
    notes = String.split(melody)
    assert length(notes) >= 7 # We might have fewer notes if rests are added
  end

  test "generates an ascending melody" do
    melody = Melody.generate(contour: :ascending, seed: 42, interval_complexity: 0, length: 5)
    notes = melody
            |> String.split()
            |> Enum.filter(fn n -> n != "-" end)
            |> Enum.map(&String.to_integer/1)
    
    # Make sure the notes generally increase (allowing some variation)
    ascending = Enum.zip(notes, tl(notes))
                |> Enum.count(fn {a, b} -> b >= a end)
    
    # Most of the notes should be ascending 
    assert ascending >= length(notes) - 2
  end

  test "generates a descending melody" do
    melody = Melody.generate(contour: :descending, seed: 42, interval_complexity: 0, length: 5)
    notes = melody
            |> String.split()
            |> Enum.filter(fn n -> n != "-" end)
            |> Enum.map(&String.to_integer/1)
    
    # Make sure the notes generally decrease (allowing some variation)
    descending = Enum.zip(notes, tl(notes))
                 |> Enum.count(fn {a, b} -> b <= a end)
    
    # Most of the notes should be descending
    assert descending >= length(notes) - 2
  end

  test "applies rhythm complexity correctly" do
    # Low rhythm complexity should have few or no rests
    simple_melody = Melody.generate(rhythm_complexity: 0, seed: 42, length: 20)
    simple_notes = String.split(simple_melody)
    simple_rests = Enum.count(simple_notes, fn n -> n == "-" end)
    
    # High rhythm complexity should have more rests
    complex_melody = Melody.generate(rhythm_complexity: 10, seed: 43, length: 20) # Use different seed
    complex_notes = String.split(complex_melody)
    complex_rests = Enum.count(complex_notes, fn n -> n == "-" end)
    
    assert complex_rests > simple_rests
  end

  test "applies interval complexity correctly" do
    # Generate with low interval complexity
    simple_melody = Melody.generate(interval_complexity: 1, seed: 42, length: 10)
    simple_notes = simple_melody
                   |> String.split()
                   |> Enum.filter(fn n -> n != "-" end)
                   |> Enum.map(&String.to_integer/1)
    
    # Calculate average interval size for simple melody
    simple_intervals = Enum.zip(simple_notes, tl(simple_notes))
                       |> Enum.map(fn {a, b} -> abs(b - a) end)
    simple_avg_interval = Enum.sum(simple_intervals) / length(simple_intervals)
    
    # Generate with high interval complexity
    complex_melody = Melody.generate(interval_complexity: 9, seed: 43, length: 10) # Different seed
    complex_notes = complex_melody
                    |> String.split()
                    |> Enum.filter(fn n -> n != "-" end)
                    |> Enum.map(&String.to_integer/1)
    
    # Calculate average interval size for complex melody
    complex_intervals = Enum.zip(complex_notes, tl(complex_notes))
                        |> Enum.map(fn {a, b} -> abs(b - a) end)
    complex_avg_interval = Enum.sum(complex_intervals) / length(complex_intervals)
    
    # Complex melody should have larger average interval sizes
    assert complex_avg_interval > simple_avg_interval
  end

  test "develops melody using inversion" do
    original = "60 64 67 72"
    inverted = Melody.develop(original, technique: :inversion)
    
    original_notes = original |> String.split() |> Enum.map(&String.to_integer/1)
    inverted_notes = inverted |> String.split() |> Enum.map(&String.to_integer/1)
    
    # The first note should be the same (pivot)
    assert hd(original_notes) == hd(inverted_notes)
    
    # Check mirroring - for each pair of notes
    # The distance from the pivot should be the same but in opposite directions
    pivot = hd(original_notes)
    
    # Each original note's distance from pivot should equal the inverted note's distance
    # but in the opposite direction
    Enum.zip(tl(original_notes), tl(inverted_notes))
    |> Enum.each(fn {orig, inv} ->
      orig_distance = orig - pivot
      inv_distance = inv - pivot
      assert_in_delta orig_distance, -inv_distance, 2 # Allow some tolerance due to enharmonic equivalents
    end)
  end

  test "develops melody using retrograde" do
    original = "60 64 67 72"
    retrograde = Melody.develop(original, technique: :retrograde)
    
    original_notes = original |> String.split() |> Enum.map(&String.to_integer/1)
    retrograde_notes = retrograde |> String.split() |> Enum.map(&String.to_integer/1)
    
    # The retrograde should be the original notes in reverse order
    assert retrograde_notes == Enum.reverse(original_notes)
  end

  test "preserves rests when developing melodies" do
    original = "60 - 64 - 67"
    retrograde = Melody.develop(original, technique: :retrograde)
    
    assert retrograde == "67 - 64 - 60"
  end

  test "combines development techniques" do
    original = "60 64 67 72 76"
    developed = Melody.develop(original, technique: :sequence, interval: 3)
    
    # The result should be different from the original and have more notes
    assert developed != original
    assert length(String.split(developed)) > length(String.split(original))
  end
  
  test "applies swing to melodies" do
    melody = Melody.swing_melody(
      contour: :ascending, 
      length: 4,
      swing: 0.5,
      seed: 42
    )
    
    # The pattern should contain both notes and durations
    assert String.contains?(melody, ":")
    
    # Check each part has the format "note:duration" with durations being 0 or 2
    parts = String.split(melody)
    for part <- parts do
      [note, duration] = String.split(part, ":")
      # Note should be integer or hyphen
      assert note == "-" || match?({_num, ""}, Integer.parse(note))
      # Duration should be 0 or 2 for strong swing
      assert duration == "0" || duration == "2"
    end
    
    # Even elements should have duration 2, odd elements duration 0 (for strong swing)
    parts_with_index = Enum.with_index(parts)
    for {part, i} <- parts_with_index do
      expected_duration = if rem(i, 2) == 0, do: "2", else: "0"
      assert String.ends_with?(part, ":" <> expected_duration)
    end
  end
  
  test "applies rhythm notation to melodies" do
    pattern = "60 64 67 72"
    rhythm = "/4 /8 /8 /4"
    
    with_rhythm = Melody.with_rhythm(pattern, rhythm)
    
    # Should have the format "note:duration"
    notes_with_durations = String.split(with_rhythm)
    assert Enum.all?(notes_with_durations, fn note -> String.contains?(note, ":") end)
    
    # Each part should be in format note:duration
    for part <- notes_with_durations do
      [note, duration] = String.split(part, ":")
      # Note should be integer
      assert match?({_num, ""}, Integer.parse(note))
      # Duration should be integer
      assert match?({_num, ""}, Integer.parse(duration))
    end
  end
end