class Token
  Occurance = Struct.new :links, :positions

  attr_accessor :word, :occurrences

  def initialize(word:,links:,positions:)
    @word, @occurrences = word, Occurance.new(links, positions)
  end
end
