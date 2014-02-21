require_relative 'database'
require_relative 'utilities/utilities'

module Lambda_Search
  class WordRank
    include Utilities

    def initialize(search_words, db_name)
      @db = Database.new db_name: db_name
      @db.connect
      @search_words = search_words
      @word_sql = get_words_sql
    end

    def rank
      rank = merge_rankings(frequency_ranking, location_ranking, diff_count_ranking)
      @db.disconnect

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

      hash.each { |item| list << { :url => item.first, :ratio => get_ratio(item) } }

      list.sort_by! { |hsh| hsh[:ratio]}.reverse
      list.each { |item| rank[item[:url]] = list.first[:ratio] / item[:ratio].to_f }

      rank
    end

    def get_ratio(item)
      values     = frequencies(item.last).values
      max_value  = values.max + 1
      sum_values = values.reduce(&:+)
      ratio      = (sum_values - max_value * @search_words.size.to_f) / max_value

      ratio.abs
    end

    def get_words_sql
      words = []
      @search_words.each { |word| words << "word = '#{word}'" }
      "where #{words.join(" or ")}"
    end
  end
end
