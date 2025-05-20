# Tejido

Tejido is an audio visual live coding system. Tejido means "fabric" in spanish.

## Prior art

This will develop on the ideas of [mixtape](https://github.com/m-onz/mixtape) where complex pattern syntax is turned into a simple "tape":

Consisting of hyphens for rests and numbers to be mapped to parameters or musical notes.

> "- - - - 3 - - - 4 - - 5"

A sequence object steps through this tape at any timing/metro resolution.

Its an incredibly simple algorithmic composition paradgym capable of creating complex output.

## Roadmap

* pattern parser for Elixir [x]
* elixir repl and udpsend [x]
* pure data & GEM system [ ]
* integration with agent systems [ ]

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
- Melodic pattern generation with configurable complexity
- Rhythmic shorthand notation
- Conditional patterns
- Harmonic constraints and voice leading
- Full MIDI note range support (1-127)
- Pure Data integration via UDP for live performance

## Installation

```elixir
def deps do
  [
    {:tejido, "~> 0.1.0"}
  ]
end
```

## Usage

### Basic Patterns

```elixir
iex> Tejido.parse("- - - 2 - 4 - 5")
"- - - 2 - 4 - 5"
```

### Rest Repetition

```elixir
iex> Tejido.parse("- -*2 4")  # Three rests followed by 4
"- - - 4"
```

### Grouping and Repetition

```elixir
iex> Tejido.parse("[ 1 2 3 ]*2")  # Group repeated twice
"1 2 3 1 2 3"

iex> Tejido.parse("[ 1 [ 2 3 ]*2 4 ]")  # Nested groups
"1 2 3 2 3 4"
```

### Randomization

```elixir
iex> Tejido.parse("?")  # Random note from full MIDI range (1-127)
"84"  # Will vary on each run

iex> Tejido.parse("?<60-72>")  # Random note between 60-72 (one octave in MIDI)
"67"  # Will vary on each run

# Create a context with a custom range for all random operations
iex> ctx = Tejido.new_context(range: {36, 48})  # Limit to bass notes
iex> Tejido.parse("?", ctx)
"42"  # Will be between 36-48

# Use custom notes for randomization
iex> ctx = Tejido.new_context(notes: ["C3", "E3", "G3"])  # C major triad
iex> Tejido.parse("?", ctx)
"E3"  # Will be one of the specified notes
```

### Euclidean Rhythms

Distributes k beats evenly across n steps using Bjorklund's algorithm.

```elixir
iex> Tejido.parse("E(3,8)")  # 3 beats distributed over 8 steps
"1 - 1 - 1 - - -"
```

### Pattern Transformation

Tejido offers a rich set of transformation functions inspired by Tidal Cycles:

```elixir
# Transpose pattern (add a value to each element)
iex> Tejido.transpose("60 62 64", 12)  # Transpose up an octave in MIDI
"72 74 76"

# Scale pattern (multiply by a factor)
iex> Tejido.scale("1 2 3", 2)
"2 4 6"

# Add two patterns (element-wise addition, shorter patterns cycle)
iex> Tejido.add("1 2 3 4", "10 20")
"11 22 13 24"

# Multiply two patterns together
iex> Tejido.multiply("1 2 3", "10 20 30")
"10 40 90"

# Map values from one range to another
iex> Tejido.map_range("1 5 10", 1, 10, 0.0, 1.0)
"0.0 0.44 1.0"

# Rotate pattern by n steps
iex> Tejido.rotate("1 2 3 4", 1)
"2 3 4 1"

# Reverse pattern
iex> Tejido.reverse("1 2 3 4")
"4 3 2 1"

# Repeat a pattern n times
iex> Tejido.repeat("1 2 3", 2)
"1 2 3 1 2 3"

# Concatenate multiple patterns
iex> Tejido.cat(["1 2 3", "4 5", "6 7 8 9"])
"1 2 3 4 5 6 7 8 9"

# Interleave multiple patterns
iex> Tejido.interleave(["1 2 3", "a b c", "x y z"])
"1 a x 2 b y 3 c z"

# Spread pattern to different length
iex> Tejido.parse("spread(1 2 3, 6)")
"1 1 2 2 3 3"

# Custom transformation function
iex> Tejido.transform("1 2 3", fn n -> 
  if n == "-", do: n, else: to_string(String.to_integer(n) * 2) 
end)
"2 4 6"
```

### Variable Substitution

```elixir
iex> Tejido.parse("$x = 1 2 3 $x")
"1 2 3"

iex> Tejido.parse("$rhythm = 1 - 1 - $melody = 5 6 7 $rhythm $melody")
"1 - 1 - 5 6 7"
```

### Musical Scales and Note Mapping

```elixir
# Scale degrees to semitones
iex> Tejido.Scales.scale_pattern("1 3 5", :major)
"0 4 7"  # C major triad intervals

# Convert to MIDI notes in a specific key
iex> "0 4 7" |> Tejido.Scales.to_midi_pattern("C", 4)
"60 64 67"  # C major triad

# Convert note names to MIDI
iex> Tejido.Scales.notes_to_midi("C4 E4 G4")
"60 64 67"

# Convert MIDI to note names
iex> Tejido.Scales.midi_to_notes("60 64 67")
"C4 E4 G4"

# Generate chord progressions
iex> Tejido.Scales.parse_chords("I IV V", :major, "C")
"0 4 7 5 9 12 7 11 14"  # C, F, G chords in semitones
```

### Parameter Modifiers

```elixir
# Add velocity to notes (0.0-1.0)
iex> Tejido.Parameters.parse("60@0.8 64@0.6 67@1.0")
%{notes: "60 64 67", velocities: "0.8 0.6 1.0"}

# Add duration to notes (in beats)
iex> Tejido.Parameters.parse("60:2 64:1 67:0.5")
%{notes: "60 64 67", durations: "2 1 0.5"}

# Combine velocity and duration
iex> Tejido.Parameters.parse("60@0.8:2 64@0.6:1 67@1.0:0.5")
%{notes: "60 64 67", velocities: "0.8 0.6 1.0", durations: "2 1 0.5"}

# Transform just the notes in a parameterized pattern
iex> pattern = "60@0.8:2 64@0.6:1 67@1.0:0.5"
iex> Tejido.Parameters.transform_param(pattern, :notes, &Tejido.transpose(&1, 12))
"72@0.8:2 76@0.6:1 79@1.0:0.5"
```

### Advanced Pattern Generation

```elixir
# Palindrome patterns
iex> Tejido.Generators.palindrome("1 2 3")
"1 2 3 2 1"

# Stuttering elements
iex> Tejido.Generators.stutter("1 2 3", 2)
"1 1 2 2 3 3"
iex> Tejido.Generators.expand_stutter("1!3 2!2 3")
"1 1 1 2 2 3"

# L-systems for fractal patterns
iex> Tejido.Generators.l_system("1", [{"1", "1 2"}, {"2", "2 1"}], 2)
"1 2 2 1"

# Polyrhythms
iex> Tejido.Generators.polyrhythm(["1 2 3 4", "a b c"], [4, 3])
"1 a 2 3 b 4 c"

# Weighted random choice
iex> Tejido.Generators.weighted_choice([{"1", 0.7}, {"2", 0.2}, {"3", 0.1}], seed: 123)
"1"
```

### Rhythm Notation

```elixir
# Convert rhythm notation to durations
iex> Tejido.Rhythm.parse("/4 /8 /8 /4")
"1.0 0.5 0.5 1.0"

# Expand rhythm patterns into note durations
iex> Tejido.Rhythm.expand_rhythm("60", "/4 /8 /8 /4")
"60:1.0 60:0.5 60:0.5 60:1.0"

# Apply swing feel
iex> Tejido.Rhythm.swing("1 2 3 4", 0.33)
"1:1.33 2:0.67 3:1.33 4:0.67"
```

### Conditional Patterns

```elixir
# Choose pattern based on condition
iex> Tejido.Conditionals.when_("true", "1 2 3", "4 5 6")
"1 2 3"

# Execute pattern every nth repetition
iex> Tejido.Conditionals.every(3, "1 2 3", "4 5 6", counter: 1)
"4 5 6"
iex> Tejido.Conditionals.every(3, "1 2 3", "4 5 6", counter: 3)
"1 2 3"

# Switch between multiple patterns
iex> Tejido.Conditionals.switch(1, ["1 2 3", "4 5 6", "7 8 9"])
"4 5 6"

# Sequence through multiple patterns
iex> sequence = ["1 2 3", "4 5 6", "7 8 9"]
iex> Tejido.Conditionals.sequence(sequence, counter: 0)
"1 2 3"
```


### Harmonic Constraints

```elixir
# Constrain notes to a scale
iex> Tejido.Harmony.constrain_to_scale("60 61 65 68", :major, "C")
"60 62 65 67"  # Maps to C major scale

# Constrain notes to a chord
iex> Tejido.Harmony.constrain_to_chord("60 61 63 66", :major, "C")
"60 60 64 67"  # Maps to C major chord (C E G)

# Progressive harmonic constraints based on chord sequence
iex> pattern = "60 63 67 70"
iex> chords = [{"C", :major}, {"F", :major}, {"G", :dominant7}]
iex> Tejido.Harmony.harmonic_sequence(pattern, chords, position: 0)
"60 64 67 72"  # Maps to C major

# Add harmonic tension/resolution
iex> Tejido.Harmony.tension("60 62 65 67", 60, 0.0)  # Full resolution
"60 64 67 72"  # Maps to stable intervals

# Apply voice leading
iex> Tejido.Harmony.voice_leading("60 70 65 72", :major, "C")
"60 67 64 72"  # Minimal movement between notes while staying in C major

# Generate chord voicings
iex> Tejido.Harmony.chord_voicing("C", :major7, style: :close)
"60 64 67 71"  # Close voicing of Cmaj7
```

### Melodic Pattern Generation

```elixir
# Generate a melody with configurable complexity parameters
iex> Tejido.Generators.Melody.generate(
  scale: :major,
  root: "C", 
  octave: 4,
  length: 8,
  contour: :ascending,
  interval_complexity: 3,
  rhythm_complexity: 5,
  consonance: 7,
  repetition: 2
)
"60 62 - 65 67 - 71 72"  # Output will vary due to randomization

# Generate different melodic contours
iex> Tejido.Generators.Melody.generate(contour: :descending, scale: :minor)
"72 69 67 - 64 62 60 -"

# Create an arch-shaped melody
iex> Tejido.Generators.Melody.generate(contour: :arch, length: 6)
"60 64 67 72 67 60"

# Apply swing feel to a melody
iex> Tejido.Generators.Melody.swing_melody(
  scale: :major,
  root: "F",
  swing: 0.5
)
"65:2 69:0 72:2 77:0 -:2 74:0 72:2 70:0"  # Format: note:duration

# Transform a melody with development techniques
iex> pattern = "60 64 67 72"
iex> Tejido.Generators.Melody.develop(pattern, technique: :inversion)
"60 56 53 48"  # Inverted around the first note

iex> Tejido.Generators.Melody.develop(pattern, technique: :retrograde)
"72 67 64 60"  # Backwards

# Create melodic sequences
iex> Tejido.Generators.Melody.develop(pattern, technique: :sequence, interval: 2)
"60 64 67 72 62 66 69 74"  # Original followed by transposed sequence
```

### Pure Data Integration

Tejido includes a REPL interface for sending patterns to Pure Data:

```elixir
# Start the interactive REPL (from project directory)
$ ./bin/tejido_pd 7000

# Inside the REPL, generate and send patterns with simple commands:
> kick complex(5)           # Send a kick drum pattern with complexity 5
> bass complex(8, 12)       # Send a bass pattern with complexity 8 and length 12
> melody minor(C, 3, 7)     # Send a C minor melody with complexity 3 and length 7
> melody swing(D, 4, 8)     # Send a swung D major melody with complexity 4 and length 8
```

An example Pure Data patch is provided in `examples/pattern_receiver.pd` that receives these patterns via UDP and routes them to appropriate instruments.

### Complex Examples

```elixir
# Combining variables, euclidean rhythms, and random elements
iex> Tejido.parse("$beat = E(3,8) $melody = 1 ?<2-5> 7 $beat [ $melody ]*2")
"1 - 1 - 1 - - - 1 3 7 1 3 7"  # Random element will vary

# Building a MIDI bass line using transformation functions
iex> base_pattern = "36 - 36 - 36 - 39 -"
iex> transposed = Tejido.transpose(base_pattern, 12)  # Up an octave
iex> combined = Tejido.add(base_pattern, "0 0 0 0 0 0 0 5")  # Add fifth to last note
iex> Tejido.interleave([base_pattern, transposed, combined])
"36 48 36 - - 36 36 - - 48 36 - 36 48 41 -"  # Complex rhythmic pattern with octaves

# Creating a generative melody with random elements and transformations
iex> motif = Tejido.parse("60 62 ?<60-67> 65")
iex> variation1 = Tejido.transpose(motif, 7)  # Up a fifth
iex> variation2 = Tejido.reverse(motif)       # Reversed
iex> Tejido.cat([motif, variation1, variation2])
"60 62 64 65 67 69 71 72 65 64 62 60"  # Random element will vary

# Creating a pattern with detailed parameters
iex> pattern = "60@0.8:2 64@0.6:1 67@1.0:0.5"  # Notes with velocity and duration
iex> swung = Tejido.Rhythm.swing(pattern, 0.33)  # Apply swing feel
iex> Tejido.Parameters.transform_param(swung, :notes, &Tejido.transpose(&1, -12))  # Transpose down
"48@0.8:1.33 52@0.6:0.67 55@1.0:0.5"  # Lower octave with swing and parameters
```

## License

MIT