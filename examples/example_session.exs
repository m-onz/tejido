#!/usr/bin/env elixir

# Ensure the Tejido application is loaded
Code.prepend_path("#{__DIR__}/../_build/dev/lib/tejido/ebin")
Application.ensure_all_started(:tejido)

alias Tejido.Generators.Melody
alias Tejido.Rhythm

# Print section header
IO.puts("\n= Example Patterns =\n")

# Generate a few kick drum patterns with different complexities
IO.puts("Kick patterns:")
1..3 |> Enum.each(fn complexity ->
  # Generate a basic rhythm pattern
  pattern = 1..8
    |> Enum.map(fn i ->
      if i == 1 || rem(i, 2) == 0 && :rand.uniform() < (1 - complexity/5) do
        "1"
      else
        "-"
      end
    end)
    |> Enum.join(" ")
    
  IO.puts("  complexity #{complexity}: #{pattern}")
end)

# Generate bass patterns with different complexities
IO.puts("\nBass patterns:")
[2, 5, 8] |> Enum.each(fn complexity ->
  pattern = Melody.generate(
    scale: :minor,
    root: "C",
    octave: 2,
    interval_complexity: complexity,
    length: 8
  )
  IO.puts("  complexity #{complexity}: #{pattern}")
end)

# Generate melodies in different scales
IO.puts("\nMelody patterns:")
[:major, :minor, :dorian, :lydian] |> Enum.each(fn scale ->
  pattern = Melody.generate(
    scale: scale,
    root: "C",
    interval_complexity: 4,
    rhythm_complexity: 3,
    length: 8
  )
  IO.puts("  #{scale}: #{pattern}")
end)

# Generate melodies with different contours
IO.puts("\nMelody contours:")
[:ascending, :descending, :arch, :valley, :random] |> Enum.each(fn contour ->
  pattern = Melody.generate(
    contour: contour,
    scale: :major,
    interval_complexity: 2,
    length: 8
  )
  IO.puts("  #{contour}: #{pattern}")
end)

# Generate swing patterns
IO.puts("\nSwing patterns:")
[0.3, 0.5, 0.7] |> Enum.each(fn swing ->
  pattern = Melody.swing_melody(
    scale: :major,
    root: "C",
    interval_complexity: 3,
    length: 8,
    swing: swing
  )
  IO.puts("  swing #{swing}: #{pattern}")
end)

# Generate patterns with different development techniques
IO.puts("\nPattern development:")
pattern = "60 64 67 72"
IO.puts("  original: #{pattern}")

[:inversion, :retrograde, :sequence, :augmentation, :diminution] |> Enum.each(fn technique ->
  developed = Melody.develop(pattern, technique: technique)
  IO.puts("  #{technique}: #{developed}")
end)

# Print a reminder of how to use the REPL
IO.puts("""

= Using the Tejido REPL =

To start the REPL and send patterns to Pure Data:

$ ./bin/tejido_pd 7000

Or using mix:

$ mix tejido 7000

Inside the REPL, you can generate and send patterns with:

> kick complex(5)
> bass complex(8, 12)
> melody minor(C, 3, 7)
> melody swing(D, 4, 8)

Make sure Pure Data is running with the example patch:
examples/pattern_receiver.pd
""")