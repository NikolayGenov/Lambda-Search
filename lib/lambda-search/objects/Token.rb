class Token
  attr_accessor :word, :link, :position

  def initialize(word:,link:,position:)
    @word, @link, @position = word, link, position
  end
end
