defmodule TejidoExtendedTest do
  use ExUnit.Case
  
  # Test musical scales and note mapping
  test "scales and note mapping" do
    # Scale degree to semitone mapping
    assert Tejido.Scales.degree_to_semitone(1, :major) == 0
    assert Tejido.Scales.degree_to_semitone(5, :major) == 7
    
    # Scale pattern mapping
    assert Tejido.Scales.scale_pattern("1 3 5", :major) == "0 4 7"
    assert Tejido.Scales.scale_pattern("1 2 3 4 5", :pentatonic_minor) == "0 3 5 7 10"
    
    # Note to MIDI conversion
    assert Tejido.Scales.note_to_midi("C4") == 60
    assert Tejido.Scales.note_to_midi("F#3") == 54
    
    # MIDI to note conversion
    assert Tejido.Scales.midi_to_note(60) == "C4"
    assert Tejido.Scales.midi_to_note(66) == "F#4"
    
    # Chord generation
    assert Tejido.Scales.chord(:major, "C") == "0 4 7"
    assert Tejido.Scales.chord(:minor7, "A") == "0 3 7 10"
    
    # Pattern of notes to MIDI
    assert Tejido.Scales.notes_to_midi("C4 E4 G4") == "60 64 67"
    assert Tejido.Scales.notes_to_midi("F3 - A3") == "53 - 57"
  end
  
  # Test parameter modifiers
  test "parameter modifiers" do
    # Parse parameters
    params = Tejido.Parameters.parse("60@0.8 64@0.5 67@1.0")
    assert params.notes == "60 64 67"
    assert params.velocities == "0.8 0.5 1.0"
    
    # Parse durations
    params = Tejido.Parameters.parse("60:2 64:1 67:0.5")
    assert params.notes == "60 64 67"
    assert params.durations == "2 1 0.5"
    
    # Parse combined parameters
    params = Tejido.Parameters.parse("60@0.8:2 64@0.6:1 67@1.0:0.5")
    assert params.notes == "60 64 67"
    assert params.velocities == "0.8 0.6 1.0"
    assert params.durations == "2 1 0.5"
    
    # Format parameters
    formatted = Tejido.Parameters.format(%{notes: "60 64 67", velocities: "0.8 0.5 1.0"})
    assert formatted == "60@0.8 64@0.5 67@1.0"
    
    # Transform parameter
    pattern = "60@0.8:2 64@0.6:1 67@1.0:0.5"
    transformed = Tejido.Parameters.transform_param(pattern, :notes, &Tejido.transpose(&1, 12))
    assert transformed == "72@0.8:2 76@0.6:1 79@1.0:0.5"
  end
  
  # Test pattern generators
  test "pattern generators" do
    # Palindrome
    assert Tejido.Generators.palindrome("1 2 3") == "1 2 3 2 1"
    assert Tejido.Generators.palindrome("1 2 3", include_middle: true) == "1 2 3 3 2 1"
    
    # Stutter
    assert Tejido.Generators.stutter("1 2 3", 2) == "1 1 2 2 3 3"
    assert Tejido.Generators.stutter("1 2 3", [3, 2, 1]) == "1 1 1 2 2 3"
    
    # Expand stutter notation
    assert Tejido.Generators.expand_stutter("1!3 2!2 3") == "1 1 1 2 2 3"
    
    # L-system
    assert Tejido.Generators.l_system("1", [{"1", "1 2"}, {"2", "2 1"}], 2) == "1 2 2 1"
  end
  
  # Test rhythm notation
  test "rhythm notation" do
    # Duration conversion
    assert Tejido.Rhythm.duration("/1") == 4
    assert Tejido.Rhythm.duration("/4") == 1
    assert Tejido.Rhythm.duration("/8.") == 2  # Rounded to integer
    
    # Rhythm parsing
    assert Tejido.Rhythm.parse("/4 /8 /8 /4") == "1 1 1 1"
    
    # Expand rhythm
    expanded = Tejido.Rhythm.expand_rhythm("60", "/4 /8 /8 /4")
    assert expanded == "60:1 60:1 60:1 60:1"
    
    # Swing
    swung = Tejido.Rhythm.swing("1 2 3 4", 0.33)
    assert swung == "1:2 2:0 3:2 4:0"  # For >= 0.3 swing value, we use "on-off" pattern
  end
  
  # Test conditional patterns
  test "conditional patterns" do
    # When condition
    assert Tejido.Conditionals.when_("true", "1 2 3", "4 5 6") == "1 2 3"
    assert Tejido.Conditionals.when_("false", "1 2 3", "4 5 6") == "4 5 6"
    
    # Every n repetitions
    assert Tejido.Conditionals.every(3, "1 2 3", "4 5 6", counter: 1) == "4 5 6"
    assert Tejido.Conditionals.every(3, "1 2 3", "4 5 6", counter: 3) == "1 2 3"
    
    # Switch based on state
    assert Tejido.Conditionals.switch(1, ["1 2 3", "4 5 6", "7 8 9"]) == "4 5 6"
    assert Tejido.Conditionals.switch(0, ["1 2 3", "4 5 6", "7 8 9"]) == "1 2 3"
    
    # Sequence through patterns
    sequence = ["1 2 3", "4 5 6", "7 8 9"]
    assert Tejido.Conditionals.sequence(sequence, counter: 0) == "1 2 3"
    assert Tejido.Conditionals.sequence(sequence, counter: 1) == "4 5 6"
  end
  
  # Test rhythmic operations (replacing integration tests)
  test "additional rhythm operations" do
    # Test with complex rhythm patterns
    expanded = Tejido.Rhythm.expand_rhythm("60 64 67", "/4. /8 /16")
    assert expanded == "60:2 64:1 67:0"
    
    # Test swing with different ratios
    light_swing = Tejido.Rhythm.swing("1 2 3 4", 0.1)
    assert light_swing == "1:2 2:2 3:2 4:2"  # All durations are 2 for small swing
    
    heavy_swing = Tejido.Rhythm.swing("1 2 3 4", 0.5)
    assert heavy_swing == "1:2 2:0 3:2 4:0"  # Alternating 2-0 for heavy swing
  end
end