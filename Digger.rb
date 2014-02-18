require './Analyzer'
require 'pp'
require './Token_Storer'
class Digger

  def initialize(page_rank_file:)
    @db = PostgresDirect.new
    @db.connect
    @page_rank = load_rank page_rank_file
  end

  def search(text)
    @search_params = Analyzer::get_words text.split(" ")
    return if @search_params.empty?
    @word_sql = get_words_sql

    rank = apply_page_rank word_rank
    @db.disconnect

    rank.sort_by { |_,v| v}.reverse
  end

  def word_rank
    merge_rankings(frequency_ranking, location_ranking, diff_count_ranking)
  end

  def apply_page_rank(word_rank)
    rank = {}

    word_rank.each do |key, value|
      page_rank_value = @page_rank[key].nil? ? 0 : @page_rank[key] #TODO Remove - bug because table got more data than rank
      rank[key] = page_rank_value * value
    end

    rank
  end

  def merge_rankings(*rankings)
    rank = {}

    rankings.each { |ranking| rank.merge!(ranking) { |key, old, new| old + new} }

    rank
  end

  def frequency_ranking
    list, rank = [], {}

    group_sql = "GROUP BY url ORDER BY count DESC"
    @db.query_select("DISTINCT url, count(*)", " #{@word_sql} #{group_sql}") { |row| list << row }
    list.each { |item| rank[item["url"]] = item["count"].to_f / list.first["count"].to_f }

    rank
  end

  def location_ranking
    list, rank = [], {}

    group_sql = "GROUP BY url ORDER BY min "
    @db.query_select(" url, MIN(position + 1) ", " #{@word_sql} #{group_sql}") { |row| list << row }
    list.each { |item| rank[item["url"]] = list.first["min"].to_f / item["min"].to_f }

    rank
  end

  def diff_count_ranking
    search_data = []
    @db.query(@word_sql) { |row| search_data << row }
    return {} if search_data.size == 1
    list, hash, rank = [], {}, {}

    search_data.each { |item| hash[item['url']] = [] }
    search_data.each { |item| hash[item['url']] << item['word'] }

    hash.each { |item| list <<  { :url => item.first , :ratio => get_ratio(item) } }

    list.sort_by! { |hsh| hsh[:ratio]}.reverse
    list.each { |item| rank[item[:url]] = list.first[:ratio] / item[:ratio].to_f }

    rank
  end

  def get_words_sql
    words = []
    @search_params.each { |param| words << "word = '#{param}'" }
    "where #{words.join(" or ")}"
  end

  def get_ratio(item)
    values     = frequencies(item.last).values
    max_value  = values.max + 1
    sum_values = values.reduce(&:+)
    ratio      = (sum_values - max_value*@search_params.size.to_f) / max_value
    ratio.abs
  end

  def frequencies(array)
    array.each_with_object Hash.new(0) do |value, result|
      result[value] += 1
    end
  end

  def load_rank(file_name)
    rank_file = File.read(file_name)
    rank_file.empty? ? {} : Marshal.load(rank_file)

  end

end

dig =  Digger.new page_rank_file: "ranks"
pp dig.search("ruby")
