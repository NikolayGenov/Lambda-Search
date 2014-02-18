require './Analyzer'
require 'pp'
require './WordRank'
class Digger

  def initialize(page_rank_file:, titles_file:, max_results:)
    @page_rank   = load_file page_rank_file
    @titles      = load_file titles_file
    @max_results = max_results
  end

  def search(text)
    @search_words = Analyzer::get_words text.split(" ")
    return if @search_words.empty?

    word_rank   = WordRank.new(@search_words).rank
    rank        = apply_page_rank word_rank
    titled_rank = add_titles rank
    titled_rank.sort_by { |_,v| v}.reverse[0..@max_results]
  end

  def apply_page_rank(word_rank)
    word_rank.each { |key, value| word_rank[key] = @page_rank[key] * value }
  end

  def add_titles(rank)
    rank.each { |item| item << @titles[item.first] }
  end

  #TODO - utils ?
  def load_file(file_name) #TODO DRY -in engine and here
    file = File.read(file_name)
    file.empty? ? {} : Marshal.load(file)
  end
end

#dig =  Digger.new page_rank_file: "ranks",titles_file: "titles", max_results:20
#pp dig.search("ruby")

