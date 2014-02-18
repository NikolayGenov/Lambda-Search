require './Analyzer'
require 'pp'
require './Token_Storer'
class Digger
  SEARCH_LIMIT = 19

  def initialize
    @db = PostgresDirect.new
    init_DB
    @search_data = []
  end

  def search(text)
    @search_params = Analyzer::get_words text.split(" ")
    return if @search_params.empty?
    wrds = []
    @search_params.each { |param| wrds << "word = '#{param}'" }
    @word_sql = "where #{wrds.join(" or ")}"
    @db.query(@word_sql) { |row| @search_data << row }
    @search_data
    #Apply page rank  
    rank[0..SEARCH_LIMIT]
  end

  def init_DB
    @db.connect
  end

  def kill_DB
    @db.disconnect
  end

  def rank
    merge_rankings(frequency_ranking, location_ranking, diff_count_ranking)
  end

  def frequency_ranking
    list = []
    rank = {}
    group_sql = "GROUP BY url ORDER BY count DESC"
    @db.query_select("DISTINCT url, count(*)", " #{@word_sql} #{group_sql}") { |row| list << row }
    list.each { |item| rank[item["url"]] = item["count"].to_f / list.first["count"].to_f }

    rank
  end

  def location_ranking
    list = []
    rank = {}

    group_sql = "GROUP BY url ORDER BY min "
    @db.query_select(" url, MIN(position + 1) ", " #{@word_sql} #{group_sql}") { |row| list << row }
    list.each { |item| rank[item["url"]] = list.first["min"].to_f / item["min"].to_f }

    rank
  end

  def diff_count_ranking
    return {} if @search_data.size == 1
    list = []
    hash = {}
    rank  = {}

    @search_data.each do |item|
      if  hash[item['url']].nil?
        hash[item['url']] = [item['word'] ]
      else
        hash[item['url']] << item['word']
      end
    end

    hash.each do |item|
      values = frequencies(item.last).values
      max_value = values.max
      sum = values.reduce(&:+)
      ratio =  (sum - (max_value*@search_params.size+ 1)).to_f.abs / (max_value + 1)
      list <<  { :url => item.first , :ratio => ratio }
    end

    list.sort_by! { |hsh| hsh[:ratio]}.reverse
    list.each { |item| rank[item[:url]] = list.first[:ratio] /  item[:ratio].to_f }

    rank
  end
  def frequencies(array)
    array.each_with_object Hash.new(0) do |value, result|
      result[value] += 1
    end
  end

  def merge_rankings(*rankings)
    rank = {}
    rankings.each { |ranking| rank.merge!(ranking) { |key, oldval, newval| oldval + newval} }
    rank.sort_by {|_,v| v }.reverse
  end
end

dig=  Digger.new
pp dig.search("hash array matz")
