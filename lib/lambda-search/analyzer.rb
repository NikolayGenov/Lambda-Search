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
