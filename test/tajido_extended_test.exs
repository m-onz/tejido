defmodule TajidoExtendedTest do
  use ExUnit.Case
  
  # Test musical scales and note mapping
  test "scales and note mapping" do
    # Scale degree to semitone mapping
    assert Tajido.Scales.degree_to_semitone(1, :major) == 0
    assert Tajido.Scales.degree_to_semitone(5, :major) == 7
    
    # Scale pattern mapping
    assert Tajido.Scales.scale_pattern("1 3 5", :major) == "0 4 7"
    assert Tajido.Scales.scale_pattern("1 2 3 4 5", :pentatonic_minor) == "0 3 5 7 10"
    
    # Note to MIDI conversion
    assert Tajido.Scales.note_to_midi("C4") == 60
    assert Tajido.Scales.note_to_midi("F#3") == 54
    
    # MIDI to note conversion
    assert Tajido.Scales.midi_to_note(60) == "C4"
    assert Tajido.Scales.midi_to_note(66) == "F#4"
    
    # Chord generation
    assert Tajido.Scales.chord(:major, "C") == "0 4 7"
    assert Tajido.Scales.chord(:minor7, "A") == "0 3 7 10"
    
    # Pattern of notes to MIDI
    assert Tajido.Scales.notes_to_midi("C4 E4 G4") == "60 64 67"
    assert Tajido.Scales.notes_to_midi("F3 - A3") == "53 - 57"
  end
  
  # Test parameter modifiers
  test "parameter modifiers" do
    # Parse parameters
    params = Tajido.Parameters.parse("60@0.8 64@0.5 67@1.0")
    assert params.notes == "60 64 67"
    assert params.velocities == "0.8 0.5 1.0"
    
    # Parse durations
    params = Tajido.Parameters.parse("60:2 64:1 67:0.5")
    assert params.notes == "60 64 67"
    assert params.durations == "2 1 0.5"
    
    # Parse combined parameters
    params = Tajido.Parameters.parse("60@0.8:2 64@0.6:1 67@1.0:0.5")
    assert params.notes == "60 64 67"
    assert params.velocities == "0.8 0.6 1.0"
    assert params.durations == "2 1 0.5"
    
    # Format parameters
    formatted = Tajido.Parameters.format(%{notes: "60 64 67", velocities: "0.8 0.5 1.0"})
    assert formatted == "60@0.8 64@0.5 67@1.0"
    
    # Transform parameter
    pattern = "60@0.8:2 64@0.6:1 67@1.0:0.5"
    transformed = Tajido.Parameters.transform_param(pattern, :notes, &Tajido.transpose(&1, 12))
    assert transformed == "72@0.8:2 76@0.6:1 79@1.0:0.5"
  end
  
  # Test pattern generators
  test "pattern generators" do
    # Palindrome
    assert Tajido.Generators.palindrome("1 2 3") == "1 2 3 2 1"
    assert Tajido.Generators.palindrome("1 2 3", include_middle: true) == "1 2 3 3 2 1"
    
    # Stutter
    assert Tajido.Generators.stutter("1 2 3", 2) == "1 1 2 2 3 3"
    assert Tajido.Generators.stutter("1 2 3", [3, 2, 1]) == "1 1 1 2 2 3"
    
    # Expand stutter notation
    assert Tajido.Generators.expand_stutter("1!3 2!2 3") == "1 1 1 2 2 3"
    
    # L-system
    assert Tajido.Generators.l_system("1", [{"1", "1 2"}, {"2", "2 1"}], 2) == "1 2 2 1"
  end
  
  # Test rhythm notation
  test "rhythm notation" do
    # Duration conversion
    assert Tajido.Rhythm.duration("/1") == 4.0
    assert Tajido.Rhythm.duration("/4") == 1.0
    assert Tajido.Rhythm.duration("/8.") == 0.75
    
    # Rhythm parsing
    assert Tajido.Rhythm.parse("/4 /8 /8 /4") == "1.0 0.5 0.5 1.0"
    
    # Expand rhythm
    expanded = Tajido.Rhythm.expand_rhythm("60", "/4 /8 /8 /4")
    assert expanded == "60:1.0 60:0.5 60:0.5 60:1.0"
    
    # Swing
    swung = Tajido.Rhythm.swing("1 2 3 4", 0.33)
    assert swung == "1:1.33 2:0.67 3:1.33 4:0.67"
  end
  
  # Test conditional patterns
  test "conditional patterns" do
    # When condition
    assert Tajido.Conditionals.when_("true", "1 2 3", "4 5 6") == "1 2 3"
    assert Tajido.Conditionals.when_("false", "1 2 3", "4 5 6") == "4 5 6"
    
    # Every n repetitions
    assert Tajido.Conditionals.every(3, "1 2 3", "4 5 6", counter: 1) == "4 5 6"
    assert Tajido.Conditionals.every(3, "1 2 3", "4 5 6", counter: 3) == "1 2 3"
    
    # Switch based on state
    assert Tajido.Conditionals.switch(1, ["1 2 3", "4 5 6", "7 8 9"]) == "4 5 6"
    assert Tajido.Conditionals.switch(0, ["1 2 3", "4 5 6", "7 8 9"]) == "1 2 3"
    
    # Sequence through patterns
    sequence = ["1 2 3", "4 5 6", "7 8 9"]
    assert Tajido.Conditionals.sequence(sequence, counter: 0) == "1 2 3"
    assert Tajido.Conditionals.sequence(sequence, counter: 1) == "4 5 6"
  end
  
  # Test rhythmic operations (replacing integration tests)
  test "additional rhythm operations" do
    # Test with complex rhythm patterns
    expanded = Tajido.Rhythm.expand_rhythm("60 64 67", "/4. /8 /16")
    assert expanded == "60:1.5 64:0.5 67:0.25"
    
    # Test swing with different ratios
    light_swing = Tajido.Rhythm.swing("1 2 3 4", 0.1)
    assert light_swing == "1:1.1 2:0.9 3:1.1 4:0.9"
    
    heavy_swing = Tajido.Rhythm.swing("1 2 3 4", 0.5)
    assert heavy_swing == "1:1.5 2:0.5 3:1.5 4:0.5"
  end
end