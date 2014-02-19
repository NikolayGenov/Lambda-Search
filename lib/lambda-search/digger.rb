require_relative 'analyzer'
require_relative 'word_rank'
require_relative 'utilities/utilities'

module Lambda_Search
  class Digger
    include Utilities

    def initialize(titles_file:,page_rank_file:, max_results:)
      @page_rank   = load_marshal_hash page_rank_file
      @titles      = load_marshal_hash titles_file
      @max_results = max_results
    end

    def search(text)
      @search_words = Analyzer::get_words text.split(" ")
      return if @search_words.empty?

      word_rank   = WordRank.new(@search_words).rank
      rank        = apply_page_rank word_rank

      titled_rank = add_titles rank.sort_by { |_,v| v}.reverse
      titled_rank.take @max_results
    end

    def apply_page_rank(word_rank)
      word_rank.each { |key, value| word_rank[key] = value * @page_rank.fetch(key, 0)  }
    end

    def add_titles(rank)
      rank.each { |item| item << @titles.fetch(item.first, "") }
    end
  end
end

#dig =  Digger.new titles_file: "titles", page_rank_file: "ranks", max_results:20
#pp dig.search("ruby")

