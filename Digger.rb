require './Analyzer'
require 'pp'
require './Token_Storer'
class Digger
  SEARCH_LIMIT = 19

  def initialize
    @db = PostgresDirect.new
    @db.connect
    @search_data = []
  end

  def search(text)
    @search_params = Analyzer::get_words text.split(" ")
    return if @search_params.empty?
    wrds = []
    @search_params.each { |param| wrds << "word = '#{param}'" }
    @word_sql = "where #{wrds.join(" or ")}"
    @db.query(@word_sql) { |row| @search_data << row }
    #Apply page rank
    rank[0..SEARCH_LIMIT]
    @db.disconnect
  end

  def rank
    merge_rankings(frequency_ranking, location_ranking, diff_count_ranking)
  end

  def merge_rankings(*rankings)
    rank = {}
    rankings.each { |ranking| rank.merge!(ranking) { |key, oldval, newval| oldval + newval} }
    rank.sort_by {|_,v| v }.reverse
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
    return {} if @search_data.size == 1
    list, hash, rank = [], {}, {}

    @search_data.each { |item| hash[item['url']] = [] }
    @search_data.each { |item| hash[item['url']] << item['word'] }

    hash.each { |item| list <<  { :url => item.first , :ratio => get_ratio(item) } }

    list.sort_by! { |hsh| hsh[:ratio]}.reverse
    list.each { |item| rank[item[:url]] = list.first[:ratio] / item[:ratio].to_f }

    rank
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

end

dig=  Digger.new
pp dig.search("hash array matz")
