defmodule OutputFormatTest do
  use ExUnit.Case
  alias Tejido.Generators.Melody

  test "melody generator outputs only contain hyphens and integer numbers" do
    # Test with a variety of configurations
    configs = [
      [scale: :major, contour: :ascending, interval_complexity: 8, rhythm_complexity: 5],
      [scale: :minor, contour: :descending, interval_complexity: 3, rhythm_complexity: 8],
      [scale: :dorian, contour: :arch, interval_complexity: 5, syncopation: 7],
      [scale: :blues, contour: :valley, rhythm_complexity: 9, repetition: 3]
    ]
    
    for config <- configs do
      melody = Melody.generate(config ++ [seed: 42])
      
      # Check pattern only contains integers and hyphens
      tokens = String.split(melody, " ")
      
      # Every token should be either a hyphen or parseable as an integer
      for token <- tokens do
        assert token == "-" || match?({_num, ""}, Integer.parse(token))
      end
    end
  end

  test "melody development outputs only contain hyphens and integer numbers" do
    # Test with various development techniques
    original = "60 64 67 72 76"
    techniques = [:inversion, :retrograde, :augmentation, :diminution, :sequence, :development]
    
    for technique <- techniques do
      developed = Melody.develop(original, technique: technique)
      
      # Print out for debugging
      IO.puts("Technique: #{technique}, Result: #{developed}")
      
      # Check pattern only contains integers and hyphens
      tokens = String.split(developed, " ")
      
      # Every token should be either a hyphen or parseable as an integer
      for token <- tokens do
        is_valid = token == "-" || match?({_num, ""}, Integer.parse(token))
        unless is_valid do
          IO.puts("Invalid token: '#{token}' in #{developed}")
        end
        assert is_valid
      end
    end
  end
end