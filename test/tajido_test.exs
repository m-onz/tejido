defmodule TajidoTest do
  use ExUnit.Case
  doctest Tajido
  
  # Helper to handle randomness in our tests
  def approximate_float(string) do
    {num, _} = Float.parse(string)
    Float.round(num, 2)
  end

  test "parses simple patterns" do
    assert Tajido.parse("- - - 2 - 4 - 5") == "- - - 2 - 4 - 5"
  end

  test "parses rest repetitions" do
    assert Tajido.parse("- -*2 4") == "- - - 4"
  end

  test "parses groups" do
    assert Tajido.parse("[ 1 2 3 ]") == "1 2 3"
  end

  test "parses groups with repetitions" do
    assert Tajido.parse("[ 1 2 3 ]*2") == "1 2 3 1 2 3"
  end

  test "parses complex patterns" do
    assert Tajido.parse("- -*2 [ 1 2 4 ]*2") == "- - - 1 2 4 1 2 4"
  end

  test "handles nested groups" do
    assert Tajido.parse("[ 1 [ 2 3 ] 4 ]") == "1 2 3 4"
  end

  test "handles nested groups with repetitions" do
    assert Tajido.parse("[ 1 [ 2 3 ]*2 4 ]") == "1 2 3 2 3 4"
  end

  # Randomization feature tests
  test "generates random notes within default range" do
    pattern = Tajido.parse("?")
    # Should be a string representation of an integer between 1 and 127
    {num, _} = Integer.parse(pattern)
    assert num >= 1 && num <= 127
  end

  test "generates random notes within specified range" do
    pattern = Tajido.parse("?<1-3>")
    assert pattern in ["1", "2", "3"]
  end

  test "combines random notes with fixed patterns" do
    pattern = Tajido.parse("1 2 ?<1-2>")
    assert String.starts_with?(pattern, "1 2 ")
    assert String.at(pattern, -1) in ["1", "2"]
  end

  # Euclidean rhythm tests
  test "generates euclidean rhythms" do
    assert Tajido.parse("E(3,8)") == "1 - 1 - 1 - - -"
    assert Tajido.parse("E(4,8)") == "1 - 1 - 1 - 1 -"
    assert Tajido.parse("E(8,8)") == "1 1 1 1 1 1 1 1"
    assert Tajido.parse("E(0,4)") == "- - - -"
  end

  # Spread pattern tests
  test "spreads patterns to match a specific length" do
    assert Tajido.parse("spread(1 2 3, 6)") == "1 1 2 2 3 3"
    assert Tajido.parse("spread(1 2 3 4, 2)") == "1 3"
  end

  # Variable substitution tests
  test "handles variable definition and substitution" do
    assert Tajido.parse("$x = 1 2 3 $x") == "1 2 3"
    assert Tajido.parse("$rhythm = 1 - 1 - $melody = 5 6 7 $rhythm $melody") == "1 - 1 - 5 6 7"
  end

  # Pattern transformation tests
  test "transforms patterns using the transform function" do
    assert Tajido.transform("1 2 3", fn n -> 
      if n == "-", do: n, else: to_string(String.to_integer(n) * 2) 
    end) == "2 4 6"
    
    # Test with rests
    assert Tajido.transform("1 - 3 -", fn n -> 
      if n == "-", do: n, else: to_string(String.to_integer(n) * 2) 
    end) == "2 - 6 -"
  end

  test "rotates patterns" do
    assert Tajido.rotate("1 2 3 4", 1) == "2 3 4 1"
    assert Tajido.rotate("1 2 3 4", -1) == "4 1 2 3"
    
    # Test with rests
    assert Tajido.rotate("1 - 3 -", 1) == "- 3 - 1"
    assert Tajido.rotate("- 2 - 4", 2) == "- 4 - 2"
  end

  test "reverses patterns" do
    assert Tajido.reverse("1 2 3 4") == "4 3 2 1"
    
    # Test with rests
    assert Tajido.reverse("1 - 3 -") == "- 3 - 1"
  end

  # Complex combinations tests
  test "combines multiple features" do
    # Define pattern with variables, euclidean rhythms, and random elements
    pattern = "$beat = E(3,8) $melody = 1 ?<2-5> 7 $beat [ $melody ]*2"
    result = Tajido.parse(pattern)
    
    # Ensure it starts with the euclidean rhythm
    assert String.starts_with?(result, "1 - 1 - 1 - - -")
    
    # Should have the melody repeated twice after the rhythm
    assert String.length(result) > 20
  end
  
  # Transformation tests
  test "transposes patterns" do
    assert Tajido.transpose("1 2 3", 12) == "13 14 15"
    assert Tajido.transpose("60 - 64 -", -12) == "48 - 52 -"
  end
  
  test "scales patterns" do
    assert Tajido.scale("1 2 3", 2) == "2 4 6"
    assert Tajido.scale("1 - 3 -", 0.5) == "0.5 - 1.5 -"
  end
  
  test "adds patterns together" do
    assert Tajido.add("1 2 3", "10 20 30") == "11 22 33"
    assert Tajido.add("1 2 3 4", "10 20") == "11 22 13 24"
    assert Tajido.add("1 - 3", "10 20 30") == "11 20 33"
  end
  
  test "multiplies patterns together" do
    assert Tajido.multiply("1 2 3", "10 20 30") == "10 40 90"
    assert Tajido.multiply("1 2 3 4", "10 20") == "10 40 30 80"
    assert Tajido.multiply("1 - 3", "10 20 30") == "10 - 90"
  end
  
  test "concatenates patterns" do
    assert Tajido.cat(["1 2 3", "4 5", "6 7 8 9"]) == "1 2 3 4 5 6 7 8 9"
    
    # Test with rests
    assert Tajido.cat(["1 - 3", "- 5", "6 - -"]) == "1 - 3 - 5 6 - -"
  end
  
  test "interleaves patterns" do
    assert Tajido.interleave(["1 2 3", "a b c", "x y z"]) == "1 a x 2 b y 3 c z"
    
    # Test with rests
    assert Tajido.interleave(["1 - 3", "a - c"]) == "1 a - - 3 c"
  end
  
  test "repeats patterns" do
    assert Tajido.repeat("1 2 3", 2) == "1 2 3 1 2 3"
    
    # Test with rests
    assert Tajido.repeat("1 - 3", 2) == "1 - 3 1 - 3"
  end
  
  test "maps values from one range to another" do
    result = Tajido.map_range("1 5 10", 1, 10, 0.0, 1.0)
    values = result |> String.split(" ") |> Enum.map(&approximate_float/1)
    assert values == [0.0, 0.44, 1.0]
    
    # Test with rests
    result_with_rests = Tajido.map_range("1 - 10", 1, 10, 0.0, 1.0)
    assert result_with_rests == "0.0 - 1.0"
  end
  
  test "combines transformation functions" do
    # Transpose then scale
    result = "60 64 67" |> Tajido.transpose(12) |> Tajido.scale(0.5)
    assert result == "36 38 39.5"
    
    # Test with rests
    result_with_rests = "60 - 67" |> Tajido.transpose(12) |> Tajido.scale(0.5)
    assert result_with_rests == "36 - 39.5"
    
    # Apply multiple transformations to create a pattern
    base = "1 2 3 4"
    transposed = Tajido.transpose(base, 60)
    octave_up = Tajido.transpose(transposed, 12)
    combined = Tajido.interleave([transposed, octave_up])
    assert combined == "61 73 62 74 63 75 64 76"
    
    # Complex pattern with rests
    base_with_rests = "1 - 3 -"
    transposed = Tajido.transpose(base_with_rests, 60)  # "61 - 63 -"
    pattern = Tajido.add(transposed, "0 12 0 7")       # "61 12 63 7"
    result = Tajido.rotate(pattern, 1)                # "12 63 7 61"
    assert result == "12 63 7 61"
  end
end