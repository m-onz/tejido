# Tejido

Tejido is an audio visual live coding system. Tejido means "fabric" in spanish.

## Prior art

This will develop on the ideas of [mixtape](https://github.com/m-onz/mixtape) where complex pattern syntax is turned into a simple "tape":

Consisting of hyphens for rests and numbers to be mapped to parameters or musical notes.

> "- - - - 3 - - - 4 - - 5"

A sequence object steps through this tape.

Its an incredibly simple algorithmic composition paradigm capable of creating complex output.

## Roadmap

* pattern parser for Elixir [x]
* elixir repl and udpsend [x]
* pure data & GEM system [ ]
* integration with agent systems [ ]

## Installation

```elixir
def deps do
  [
    {:tejido, "~> 0.1.0"}
  ]
end
```

## License

MIT
