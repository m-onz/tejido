defmodule Tejido.Parameters do
  @moduledoc """
  Adds support for parameter modifiers to Tejido patterns.
  Allows specifying attributes like velocity, duration, etc. 
  for each note in a pattern.
  """

  @doc """
  Parses a pattern with parameters and separates into component parts.
  
  Supported formats:
  - `note@velocity` - Note with velocity (0.0-1.0)
  - `note:duration` - Note with duration in beats
  - `note@velocity:duration` - Note with both parameters
  
  ## Examples
      iex> Tejido.Parameters.parse("60@0.8 64@0.5 67@1.0")
      %{notes: "60 64 67", velocities: "0.8 0.5 1.0"}
      
      iex> Tejido.Parameters.parse("60:2 64:1 67:0.5")
      %{notes: "60 64 67", durations: "2 1 0.5"}
      
      iex> Tejido.Parameters.parse("60@0.8:2 64@0.6:1 67@1.0:0.5")
      %{notes: "60 64 67", velocities: "0.8 0.6 1.0", durations: "2 1 0.5"}
  """
  def parse(pattern) do
    elements = pattern
    |> String.split(" ", trim: true)
    |> Enum.map(&parse_element/1)
    
    # Extract notes and parameters
    notes = Enum.map(elements, & &1.note) |> Enum.join(" ")
    
    # Only include parameters that are actually used
    result = %{notes: notes}
    
    # Add velocities if any element has them
    result = if Enum.any?(elements, & &1.velocity != nil) do
      velocities = Enum.map(elements, fn e -> 
        case e.velocity do
          nil -> "1.0" # Default velocity
          v -> v
        end
      end) |> Enum.join(" ")
      
      Map.put(result, :velocities, velocities)
    else
      result
    end
    
    # Add durations if any element has them
    result = if Enum.any?(elements, & &1.duration != nil) do
      durations = Enum.map(elements, fn e -> 
        case e.duration do
          nil -> "1.0" # Default duration of one beat
          d -> d
        end
      end) |> Enum.join(" ")
      
      Map.put(result, :durations, durations)
    else
      result
    end
    
    result
  end
  
  @doc """
  Formats a pattern with parameters into the combined notation.
  
  ## Examples
      iex> Tejido.Parameters.format(%{notes: "60 64 67", velocities: "0.8 0.5 1.0"})
      "60@0.8 64@0.5 67@1.0"
      
      iex> Tejido.Parameters.format(%{notes: "60 64 67", durations: "2 1 0.5"})
      "60:2 64:1 67:0.5"
      
      iex> Tejido.Parameters.format(%{notes: "60 64 67", velocities: "0.8 0.6 1.0", durations: "2 1 0.5"})
      "60@0.8:2 64@0.6:1 67@1.0:0.5"
  """
  def format(params) do
    notes = String.split(params.notes, " ", trim: true)
    
    velocities = if Map.has_key?(params, :velocities) do
      String.split(params.velocities, " ", trim: true)
    else
      List.duplicate(nil, length(notes))
    end
    
    durations = if Map.has_key?(params, :durations) do
      String.split(params.durations, " ", trim: true)
    else
      List.duplicate(nil, length(notes))
    end
    
    Enum.zip_with([notes, velocities, durations], fn [note, velocity, duration] ->
      format_element(%{note: note, velocity: velocity, duration: duration})
    end)
    |> Enum.join(" ")
  end
  
  @doc """
  Applies a transformation to a specific parameter in a parameterized pattern.
  
  ## Examples
      iex> pattern = "60@0.8:2 64@0.6:1 67@1.0:0.5"
      iex> Tejido.Parameters.transform_param(pattern, :notes, &Tejido.transpose(&1, 12))
      "72@0.8:2 76@0.6:1 79@1.0:0.5"
      
      iex> pattern = "60@0.8:2 64@0.6:1 67@1.0:0.5"
      iex> Tejido.Parameters.transform_param(pattern, :velocities, &Tejido.scale(&1, 0.5))
      "60@0.4:2 64@0.3:1 67@0.5:0.5"
      
      iex> pattern = "60@0.8:2 64@0.6:1 67@1.0:0.5"
      iex> Tejido.Parameters.transform_param(pattern, :durations, &Tejido.scale(&1, 2))
      "60@0.8:4 64@0.6:2 67@1.0:1.0"
  """
  def transform_param(pattern, param, transform_fn) do
    params = parse(pattern)
    
    # Apply transformation to the specified parameter
    transformed_param = case param do
      :notes -> transform_fn.(params.notes)
      :velocities -> transform_fn.(params.velocities)
      :durations -> transform_fn.(params.durations)
    end
    
    # Update the parameter in the params map
    updated_params = Map.put(params, param, transformed_param)
    
    # Format back to the combined pattern
    format(updated_params)
  end
  
  @doc """
  Extracts a specific parameter from a parameterized pattern.
  
  ## Examples
      iex> Tejido.Parameters.get_param("60@0.8:2 64@0.6:1 67@1.0:0.5", :notes)
      "60 64 67"
      
      iex> Tejido.Parameters.get_param("60@0.8:2 64@0.6:1 67@1.0:0.5", :velocities)
      "0.8 0.6 1.0"
      
      iex> Tejido.Parameters.get_param("60@0.8:2 64@0.6:1 67@1.0:0.5", :durations)
      "2 1 0.5"
  """
  def get_param(pattern, param) do
    params = parse(pattern)
    case param do
      :notes -> params.notes
      :velocities -> Map.get(params, :velocities, "")
      :durations -> Map.get(params, :durations, "")
      _ -> ""
    end
  end
  
  # Private helpers
  
  # Parse a single element with parameters
  defp parse_element(element) do
    # Default structure
    parsed = %{note: element, velocity: nil, duration: nil}
    
    # Check for velocity parameter (@)
    case String.split(element, "@", parts: 2) do
      [note, rest] ->
        # Handle duration parameter after velocity
        case String.split(rest, ":", parts: 2) do
          [velocity, duration] ->
            %{parsed | note: note, velocity: velocity, duration: duration}
          [velocity] ->
            %{parsed | note: note, velocity: velocity}
        end
      [element] ->
        # Check for duration parameter (:) without velocity
        case String.split(element, ":", parts: 2) do
          [note, duration] ->
            %{parsed | note: note, duration: duration}
          [_note] ->
            parsed
        end
    end
  end
  
  # Format a single element with parameters
  defp format_element(params) do
    note = params.note
    
    # Add velocity if present
    with_velocity = if params.velocity do
      "#{note}@#{params.velocity}"
    else
      note
    end
    
    # Add duration if present
    if params.duration do
      "#{with_velocity}:#{params.duration}"
    else
      with_velocity
    end
  end
end