require 'stopwords'
require 'stemmer'
require 'unicode'
require_relative 'objects/page'
require_relative 'objects/token'

module Lambda_Search
  class Analyzer
    @@stopwords = Stopwords::STOP_WORDS
    def analyze(page)
      tokens = Analyzer::keywords_position_pairs(page.content).map do |keyword, position|
        Objects::Token.new word: keyword, link: page.url, position: position
      end
      tokens
    end

    class << self
      def get_words(string)
        stem_words remove_stopwords extract_words string
      end

      def keywords_position_pairs(content)
        words = get_words content
        words.map.each_with_index { |keyword, index|  [keyword, index] }
      end

      def extract_words(content)
        content.map do |element|
          Unicode.downcase(element).strip.gsub(/[^[[:alnum:]]\s]/, '').split(" ")
        end.reject(&:empty?).flatten
      end

      def remove_stopwords(content)
        content.reject { |word| @@stopwords.include? word }
      end

      def stem_words(content)
        content.map(&:stem)
      end
    end
  end
end

# page = Page.new url: "www.google.com", content:
#   ["Wikipedia, the free encyclopedia", "Main Page", "From Wikipedia, the free encyclopedia", "navigation",  "search", "Welcome to ", "Wikipedia", ",", "the ", "free", "encyclopedia", " that ", "anyone can edit", ".", "4,433,942", " articles in ", "English", "Arts", "Biography", "Geography", "History", "Mathematics", "Science", "Society", "Technology", "All portals", "From today's featured article", "Crocodilia", " is an ", "order", " of large, ", "predatory", ", ", "semi-aquatic", "reptiles", ". They appeared in the Late ", "Cretaceous", ", and include ", "true crocodiles", ", ", "alligators", ", ", "caimans", ", and ", "gharials", ". Solidly built animals, they have long flattened snouts, eyes, ears, and nostrils at the top of the head and laterally compressed tails. Their skin is thick and covered in scales;"],
#   links: ["www.facebook.com"]
# 
# an =  Analyzer.new.analyze page
# p an
