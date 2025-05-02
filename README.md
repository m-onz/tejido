# Tajido

Tajido is a live coding pattern parser for Elixir, designed for music and algorithmic composition. It can be used with MIDI, OSC, or any other output mechanism for live performances.

## Features

- Basic pattern parsing with rests (`-`) and notes
- Grouping with `[` and `]` 
- Repetition with `*n` syntax
- Randomization with `?` (full range) and `?<min-max>` (specific range)
- Euclidean rhythms with `E(k,n)` notation
- Pattern transformations:
  - Transpose - shifts numeric values up/down
  - Scale - multiplies values by a factor
  - Add/multiply - combine patterns arithmetically
  - Rotate/reverse - reorder elements
  - Map_range - rescale values from one range to another
- Pattern composition:
  - Cat - concatenate multiple patterns
  - Interleave - weave multiple patterns together
  - Repeat - duplicate patterns
- Variable substitution with `$var = pattern`
- Musical scales and chord progressions
- Parameter modifiers for velocity and duration
- Advanced pattern generation algorithms
- Rhythmic shorthand notation
- Conditional patterns
- Harmonic constraints and voice leading
- Full MIDI note range support (1-127)

## Installation

```elixir
def deps do
  [
    {:tajido, "~> 0.1.0"}
  ]
end
```

## Usage

### Basic Patterns

```elixir
iex> Tajido.parse("- - - 2 - 4 - 5")
"- - - 2 - 4 - 5"
```

### Rest Repetition

```elixir
iex> Tajido.parse("- -*2 4")  # Three rests followed by 4
"- - - 4"
```

### Grouping and Repetition

```elixir
iex> Tajido.parse("[ 1 2 3 ]*2")  # Group repeated twice
"1 2 3 1 2 3"

iex> Tajido.parse("[ 1 [ 2 3 ]*2 4 ]")  # Nested groups
"1 2 3 2 3 4"
```

### Randomization

```elixir
iex> Tajido.parse("?")  # Random note from full MIDI range (1-127)
"84"  # Will vary on each run

iex> Tajido.parse("?<60-72>")  # Random note between 60-72 (one octave in MIDI)
"67"  # Will vary on each run

# Create a context with a custom range for all random operations
iex> ctx = Tajido.new_context(range: {36, 48})  # Limit to bass notes
iex> Tajido.parse("?", ctx)
"42"  # Will be between 36-48

# Use custom notes for randomization
iex> ctx = Tajido.new_context(notes: ["C3", "E3", "G3"])  # C major triad
iex> Tajido.parse("?", ctx)
"E3"  # Will be one of the specified notes
```

### Euclidean Rhythms

Distributes k beats evenly across n steps using Bjorklund's algorithm.

```elixir
iex> Tajido.parse("E(3,8)")  # 3 beats distributed over 8 steps
"1 - 1 - 1 - - -"
```

### Pattern Transformation

Tajido offers a rich set of transformation functions inspired by Tidal Cycles:

```elixir
# Transpose pattern (add a value to each element)
iex> Tajido.transpose("60 62 64", 12)  # Transpose up an octave in MIDI
"72 74 76"

# Scale pattern (multiply by a factor)
iex> Tajido.scale("1 2 3", 2)
"2 4 6"

# Add two patterns (element-wise addition, shorter patterns cycle)
iex> Tajido.add("1 2 3 4", "10 20")
"11 22 13 24"

# Multiply two patterns together
iex> Tajido.multiply("1 2 3", "10 20 30")
"10 40 90"

# Map values from one range to another
iex> Tajido.map_range("1 5 10", 1, 10, 0.0, 1.0)
"0.0 0.44 1.0"

# Rotate pattern by n steps
iex> Tajido.rotate("1 2 3 4", 1)
"2 3 4 1"

# Reverse pattern
iex> Tajido.reverse("1 2 3 4")
"4 3 2 1"

# Repeat a pattern n times
iex> Tajido.repeat("1 2 3", 2)
"1 2 3 1 2 3"

# Concatenate multiple patterns
iex> Tajido.cat(["1 2 3", "4 5", "6 7 8 9"])
"1 2 3 4 5 6 7 8 9"

# Interleave multiple patterns
iex> Tajido.interleave(["1 2 3", "a b c", "x y z"])
"1 a x 2 b y 3 c z"

# Spread pattern to different length
iex> Tajido.parse("spread(1 2 3, 6)")
"1 1 2 2 3 3"

# Custom transformation function
iex> Tajido.transform("1 2 3", fn n -> 
  if n == "-", do: n, else: to_string(String.to_integer(n) * 2) 
end)
"2 4 6"
```

### Variable Substitution

```elixir
iex> Tajido.parse("$x = 1 2 3 $x")
"1 2 3"

iex> Tajido.parse("$rhythm = 1 - 1 - $melody = 5 6 7 $rhythm $melody")
"1 - 1 - 5 6 7"
```

### Musical Scales and Note Mapping

```elixir
# Scale degrees to semitones
iex> Tajido.Scales.scale_pattern("1 3 5", :major)
"0 4 7"  # C major triad intervals

# Convert to MIDI notes in a specific key
iex> "0 4 7" |> Tajido.Scales.to_midi_pattern("C", 4)
"60 64 67"  # C major triad

# Convert note names to MIDI
iex> Tajido.Scales.notes_to_midi("C4 E4 G4")
"60 64 67"

# Convert MIDI to note names
iex> Tajido.Scales.midi_to_notes("60 64 67")
"C4 E4 G4"

# Generate chord progressions
iex> Tajido.Scales.parse_chords("I IV V", :major, "C")
"0 4 7 5 9 12 7 11 14"  # C, F, G chords in semitones
```

### Parameter Modifiers

```elixir
# Add velocity to notes (0.0-1.0)
iex> Tajido.Parameters.parse("60@0.8 64@0.6 67@1.0")
%{notes: "60 64 67", velocities: "0.8 0.6 1.0"}

# Add duration to notes (in beats)
iex> Tajido.Parameters.parse("60:2 64:1 67:0.5")
%{notes: "60 64 67", durations: "2 1 0.5"}

# Combine velocity and duration
iex> Tajido.Parameters.parse("60@0.8:2 64@0.6:1 67@1.0:0.5")
%{notes: "60 64 67", velocities: "0.8 0.6 1.0", durations: "2 1 0.5"}

# Transform just the notes in a parameterized pattern
iex> pattern = "60@0.8:2 64@0.6:1 67@1.0:0.5"
iex> Tajido.Parameters.transform_param(pattern, :notes, &Tajido.transpose(&1, 12))
"72@0.8:2 76@0.6:1 79@1.0:0.5"
```

### Advanced Pattern Generation

```elixir
# Palindrome patterns
iex> Tajido.Generators.palindrome("1 2 3")
"1 2 3 2 1"

# Stuttering elements
iex> Tajido.Generators.stutter("1 2 3", 2)
"1 1 2 2 3 3"
iex> Tajido.Generators.expand_stutter("1!3 2!2 3")
"1 1 1 2 2 3"

# L-systems for fractal patterns
iex> Tajido.Generators.l_system("1", [{"1", "1 2"}, {"2", "2 1"}], 2)
"1 2 2 1"

# Polyrhythms
iex> Tajido.Generators.polyrhythm(["1 2 3 4", "a b c"], [4, 3])
"1 a 2 3 b 4 c"

# Weighted random choice
iex> Tajido.Generators.weighted_choice([{"1", 0.7}, {"2", 0.2}, {"3", 0.1}], seed: 123)
"1"
```

### Rhythm Notation

```elixir
# Convert rhythm notation to durations
iex> Tajido.Rhythm.parse("/4 /8 /8 /4")
"1.0 0.5 0.5 1.0"

# Expand rhythm patterns into note durations
iex> Tajido.Rhythm.expand_rhythm("60", "/4 /8 /8 /4")
"60:1.0 60:0.5 60:0.5 60:1.0"

# Apply swing feel
iex> Tajido.Rhythm.swing("1 2 3 4", 0.33)
"1:1.33 2:0.67 3:1.33 4:0.67"
```

### Conditional Patterns

```elixir
# Choose pattern based on condition
iex> Tajido.Conditionals.when_("true", "1 2 3", "4 5 6")
"1 2 3"

# Execute pattern every nth repetition
iex> Tajido.Conditionals.every(3, "1 2 3", "4 5 6", counter: 1)
"4 5 6"
iex> Tajido.Conditionals.every(3, "1 2 3", "4 5 6", counter: 3)
"1 2 3"

# Switch between multiple patterns
iex> Tajido.Conditionals.switch(1, ["1 2 3", "4 5 6", "7 8 9"])
"4 5 6"

# Sequence through multiple patterns
iex> sequence = ["1 2 3", "4 5 6", "7 8 9"]
iex> Tajido.Conditionals.sequence(sequence, counter: 0)
"1 2 3"
```


### Harmonic Constraints

```elixir
# Constrain notes to a scale
iex> Tajido.Harmony.constrain_to_scale("60 61 65 68", :major, "C")
"60 62 65 67"  # Maps to C major scale

# Constrain notes to a chord
iex> Tajido.Harmony.constrain_to_chord("60 61 63 66", :major, "C")
"60 60 64 67"  # Maps to C major chord (C E G)

# Progressive harmonic constraints based on chord sequence
iex> pattern = "60 63 67 70"
iex> chords = [{"C", :major}, {"F", :major}, {"G", :dominant7}]
iex> Tajido.Harmony.harmonic_sequence(pattern, chords, position: 0)
"60 64 67 72"  # Maps to C major

# Add harmonic tension/resolution
iex> Tajido.Harmony.tension("60 62 65 67", 60, 0.0)  # Full resolution
"60 64 67 72"  # Maps to stable intervals

# Apply voice leading
iex> Tajido.Harmony.voice_leading("60 70 65 72", :major, "C")
"60 67 64 72"  # Minimal movement between notes while staying in C major

# Generate chord voicings
iex> Tajido.Harmony.chord_voicing("C", :major7, style: :close)
"60 64 67 71"  # Close voicing of Cmaj7
```

### Complex Examples

```elixir
# Combining variables, euclidean rhythms, and random elements
iex> Tajido.parse("$beat = E(3,8) $melody = 1 ?<2-5> 7 $beat [ $melody ]*2")
"1 - 1 - 1 - - - 1 3 7 1 3 7"  # Random element will vary

# Building a MIDI bass line using transformation functions
iex> base_pattern = "36 - 36 - 36 - 39 -"
iex> transposed = Tajido.transpose(base_pattern, 12)  # Up an octave
iex> combined = Tajido.add(base_pattern, "0 0 0 0 0 0 0 5")  # Add fifth to last note
iex> Tajido.interleave([base_pattern, transposed, combined])
"36 48 36 - - 36 36 - - 48 36 - 36 48 41 -"  # Complex rhythmic pattern with octaves

# Creating a generative melody with random elements and transformations
iex> motif = Tajido.parse("60 62 ?<60-67> 65")
iex> variation1 = Tajido.transpose(motif, 7)  # Up a fifth
iex> variation2 = Tajido.reverse(motif)       # Reversed
iex> Tajido.cat([motif, variation1, variation2])
"60 62 64 65 67 69 71 72 65 64 62 60"  # Random element will vary

# Creating a pattern with detailed parameters
iex> pattern = "60@0.8:2 64@0.6:1 67@1.0:0.5"  # Notes with velocity and duration
iex> swung = Tajido.Rhythm.swing(pattern, 0.33)  # Apply swing feel
iex> Tajido.Parameters.transform_param(swung, :notes, &Tajido.transpose(&1, -12))  # Transpose down
"48@0.8:1.33 52@0.6:0.67 55@1.0:0.5"  # Lower octave with swing and parameters
```

## License

MIT
