require 'logger'
require 'crawler'
require 'analyzer'
require 'database'
require 'utilities/utilities'

module Lambda_Search
  class Engine
    include Utilities
    def initialize(options = {})
      @options = options
      @crawler = Crawler.new
      @analyzer = Analyzer.new @options[:user_agent]
      @db = PostgresDirect.new db_name: @options[:db_name]
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
      @db.create_table
      @db.prepare_insert_statement
    end

    def kill_DB
      # @db.drop_table
      @db.disconnect
    end

    #TODO - remove
    def get_data
      @db.query{|row| printf("%d \n", row['id'] )}
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
          url = @urls_to_crawl[count]
          if @crawler.crawlable? url and not crawled? url
            count = process_page url, count
            p count
          end
        rescue URI::InvalidURIError
          @logger.error "Invalid URI link: #{url}"
        rescue OpenURI::HTTPError
          @logger.error "HTTP Error opening: #{url}"
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
      # kill_DB
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

#en = Engine.new crawled_file: "crawled.txt", to_crawl_file: "to_crawl.txt", logger_file: "logfile.log",
# graph_file: "graph",titles_file: "titles",  max_urls: 1000 , db_name: "development", user_agent: "lambda-crawler"
# en.process("http://en.wikipedia.com/")
# en.process("http://google.com/")
#en.process(["http://fmi.ruby.bg/"])
# en.get_data
