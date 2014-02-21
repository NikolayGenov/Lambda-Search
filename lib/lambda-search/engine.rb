require 'logger'
require_relative 'crawler'
require_relative 'analyzer'
require_relative 'database'
require_relative 'utilities/utilities'

module Lambda_Search
  class Engine
    include Utilities
    def initialize(options = {})
      @options = options
      @crawler = Crawler.new user_agent: @options[:user_agent]
      @analyzer = Analyzer.new
      @db = Database.new db_name: @options[:db_name]
      @logger = Logger.new @options[:logger_file]
      load_data
      init_DB
    end

    def load_data()
      @crawled_urls  = read_text_lines   @options[:crawled_file]
      @urls_to_crawl = read_text_lines   @options[:to_crawl_file]
      @graph         = load_marshal_hash @options[:graph_file]
      @titles        = load_marshal_hash @options[:titles_file]
    end

    def init_DB
      @db.connect
      @db.create_table unless @db.table_exist?
      @db.prepare_insert_statement
    end

    def kill_DB
      #@db.drop_table #if you want to delete the current table
      @db.disconnect
    end

    def crawled?(url)
      @crawled_urls.include? url
    end

    def write_links_to_files
      write_text_lines     @options[:to_crawl_file], @urls_to_crawl
      write_text_lines     @options[:crawled_file],  @crawled_urls
      marshal_dump_to_file @options[:graph_file],    @graph
      marshal_dump_to_file @options[:titles_file],   @titles
    end

    def process(seed)
      count = 0
      add_to_crawl seed
      until @urls_to_crawl.empty? or count == @options[:max_urls]
        begin
          url = @urls_to_crawl.first
          if @crawler.crawlable? url and not crawled? url
            count = process_page url, count
          end
        rescue URI::InvalidURIError
          @logger.error "Invalid URI link: #{url}"
        rescue OpenURI::HTTPError
          @logger.error "HTTP Error opening: #{url}"
        rescue ArgumentError => e
          @logger.error "Argument Error #{e} opening: #{url}"
        rescue SocketError => e
          @logger.error "Socket error #{e}  opening: #{url}"
        rescue SystemCallError => e
          @logger.error "System call error #{e}  opening: #{url}"
        rescue RuntimeError => e
          @logger.error "Error: #{e} with this: #{url}"
        ensure
          @crawled_urls << url
          @urls_to_crawl.delete url
        end
      end
    ensure
      write_links_to_files
      kill_DB
    end

    def add_to_crawl(seed)
      seed.each { |url| @urls_to_crawl << url }
    end

    def process_page(url, count)
      page = @crawler.crawl url
      add_words_to_DB @analyzer.analyze page
      save_additional_url_data url, page
      count + 1
    end

    def save_additional_url_data(url, page)
      @titles[url] = page.title
      @graph[url] = page.links #used by PageRank
      @urls_to_crawl += page.links
    end

    def add_words_to_DB(tokens)
      @db.transaction do
        tokens.each { |token| @db.add_word(token.word, token.link, token.position) }
      end
    end
  end
end
