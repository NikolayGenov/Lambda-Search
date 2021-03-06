require_relative 'utilities/utilities'

module Lambda_Search
  class PageRank
    include Utilities

    DAMPING_FACTOR = 0.8
    NUMBER_LOOPS = 10

    def initialize(graph_file:, page_rank_file:)
      @graph          = Marshal.load File.read graph_file
      @number_pages   = @graph.size
      @page_rank_file = page_rank_file
      @ranks          = {}
      init_ranks
    end

    def init_ranks
      @graph.keys.each { |url| @ranks[url] = 1.0 / @number_pages }
    end

    def calculate_ranks(number_of_loops)
      number_of_loops.times { @ranks = get_new_hash_ranks }

      @ranks
    end

    def save_ranks
      marshal_dump_to_file @page_rank_file, calculate_ranks(NUMBER_LOOPS)
    end

    def get_new_rank(page)
      newrank = (1 - DAMPING_FACTOR) / @number_pages

      @graph.values.each do |node|
        if node.include? page
          newrank += DAMPING_FACTOR * (@ranks[page] / node.size)
        end
      end

      newrank
    end

    def get_new_hash_ranks
      newranks = {}

      @graph.keys.each { |page| newranks[page] = get_new_rank page }

      newranks
    end
  end
end
