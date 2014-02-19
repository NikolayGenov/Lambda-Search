require_relative 'digger'

module Lambda_Search
  class Search_Interface
    def initialize(page_rank_file:, titles_file:,max_results:, db_name:)
      @digger = Digger.new page_rank_file: page_rank_file,
        titles_file: titles_file, max_results: max_results, db_name: db_name
      @time_start, @time_endi = 0, 0
    end

    def search(input)
      @time_start = Time.now
      results = @digger.search input
      @time_end = Time.now
      results
    end

    def time_taken
      @time_end - @time_start
    end

    def display_results(input)
    end

  end
end
