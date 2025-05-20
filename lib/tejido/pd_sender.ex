defmodule Tejido.PDSender do
  @moduledoc """
  A module for sending patterns to Pure Data via UDP.
  Provides a REPL interface for generating and sending patterns.
  """

  alias Tejido.Generators.Melody
  alias Tejido.Rhythm

  @doc """
  Opens a UDP socket and starts an interactive pattern generation session.
  """
  def start(port \\ 7000) do
    {:ok, socket} = :gen_udp.open(0)

    IO.puts("""
    === Tejido Pattern Generator for Pure Data ===
    Sending to localhost:#{port}
    
    Commands:
      kick complex(5)          # Send a kick pattern with complexity 5
      bass complex(8, 12)      # Send a bass pattern with complexity 8 and length 12
      melody minor(C, 3, 7)    # Send a C minor melody, complexity 3, length 7
      melody swing(D, 4, 8)    # Send a swung D major melody, complexity 4, length 8
      exit                     # Quit the application
    """)

    interactive_loop(socket, port)
  end

  @doc """
  Sends a single pattern to Pure Data.
  """
  def send_pattern(pattern, port \\ 7000) do
    {:ok, socket} = :gen_udp.open(0)
    formatted_message = format_message(pattern)

    result = :gen_udp.send(socket, {127, 0, 0, 1}, port, formatted_message)
    IO.puts("Sent: #{pattern}")
    IO.puts("Result: #{inspect(result)}")

    :gen_udp.close(socket)
  end

  # Private functions

  defp interactive_loop(socket, port) do
    case IO.gets("> ") do
      :eof ->
        IO.puts("EOF received, exiting...")
        :gen_udp.close(socket)

      {:error, reason} ->
        IO.puts("Error: #{inspect(reason)}, exiting...")
        :gen_udp.close(socket)

      input ->
        input = String.trim(input)

        if input == "exit" do
          IO.puts("Exiting...")
          :gen_udp.close(socket)
        else
          # Parse the command and generate pattern
          {target, pattern} = parse_command(input)
          
          if pattern do
            # Format and send message
            formatted_message = format_message("#{target} #{pattern}")
            result = :gen_udp.send(socket, {127, 0, 0, 1}, port, formatted_message)
            IO.puts("Sent to #{target}: #{pattern}")
          end

          # Continue the loop
          interactive_loop(socket, port)
        end
    end
  end

  defp format_message(message) do
    # Remove trailing semicolon and newline if present
    message = message
      |> String.trim_trailing(";")
      |> String.trim_trailing("\n")

    # Add semicolon and newline, then convert to charlist
    (message <> ";\n") |> String.to_charlist()
  end

  defp parse_command(command) do
    cond do
      # Match kick complex pattern
      kick_complex = Regex.run(~r/^kick\s+complex\((\d+)(?:,\s*(\d+))?\)$/, command) ->
        [_, complexity, length] = if length(kick_complex) == 3, do: kick_complex, else: kick_complex ++ [nil]
        complexity = parse_integer(complexity, 5)
        length = parse_integer(length, 8)
        
        pattern = generate_rhythm_pattern(complexity, length)
        {"kick", pattern}

      # Match bass complex pattern
      bass_complex = Regex.run(~r/^bass\s+complex\((\d+)(?:,\s*(\d+))?\)$/, command) ->
        [_, complexity, length] = if length(bass_complex) == 3, do: bass_complex, else: bass_complex ++ [nil]
        complexity = parse_integer(complexity, 5)
        length = parse_integer(length, 8)
        
        pattern = Melody.generate(
          scale: :minor,
          contour: :random,
          interval_complexity: complexity,
          rhythm_complexity: complexity,
          length: length,
          octave: 2
        )
        {"bass", pattern}

      # Match melody pattern in specified scale
      melody_scale = Regex.run(~r/^melody\s+(major|minor)\(([A-G][#b]?),\s*(\d+)(?:,\s*(\d+))?\)$/, command) ->
        [_, scale, root, complexity, length] = 
          if length(melody_scale) == 5, do: melody_scale, else: melody_scale ++ [nil]
        
        scale_atom = String.to_atom(scale)
        complexity = parse_integer(complexity, 5)
        length = parse_integer(length, 8)
        
        pattern = Melody.generate(
          scale: scale_atom,
          root: root,
          interval_complexity: complexity,
          rhythm_complexity: complexity,
          repetition: complexity,
          length: length,
          octave: 4
        )
        {"melody", pattern}

      # Match swung melody pattern
      melody_swing = Regex.run(~r/^melody\s+swing\(([A-G][#b]?),\s*(\d+)(?:,\s*(\d+))?\)$/, command) ->
        [_, root, complexity, length] = 
          if length(melody_swing) == 4, do: melody_swing, else: melody_swing ++ [nil]
        
        complexity = parse_integer(complexity, 5)
        length = parse_integer(length, 8)
        
        pattern = Melody.swing_melody(
          scale: :major,
          root: root,
          interval_complexity: complexity,
          rhythm_complexity: complexity,
          length: length,
          octave: 4,
          swing: 0.5
        )
        {"melody", pattern}

      # Unknown command
      true ->
        IO.puts("Unknown command: #{command}")
        IO.puts("""
        Try:
          kick complex(5)
          bass complex(8, 12)
          melody minor(C, 3, 7)
          melody swing(D, 4, 8)
        """)
        {nil, nil}
    end
  end

  defp parse_integer(value, default) when is_binary(value), do: String.to_integer(value)
  defp parse_integer(nil, default), do: default

  defp generate_rhythm_pattern(complexity, length) do
    # For rhythms, we'll use a simpler pattern of just 1s and -s
    # Higher complexity means more varied rhythms with rests

    # Base probabilities
    beat_probability = max(0.8, 1 - (complexity / 20))  # 5 -> 0.75, 10 -> 0.5
    
    # Generate a basic pattern
    base_pattern = 1..length
    |> Enum.map(fn i ->
      # First beat always hits
      if i == 1 || :rand.uniform() < beat_probability do
        "1"
      else
        "-"
      end
    end)
    |> Enum.join(" ")
    
    # Add swing for complexity > 5
    if complexity > 5 do
      Rhythm.swing(base_pattern, min(1.0, complexity / 10))
    else
      base_pattern
    end
  end
end