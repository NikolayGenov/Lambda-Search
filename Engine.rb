require 'logger'
require './Crawler'
require './Analyzer'
require './Token_Storer'
class Engine
  def initialize(options = {})
    @options = options
    @crawler = Crawler.new
    @analyzer = Analyzer.new
    @db = PostgresDirect.new
    @count = 0
    @logger = Logger.new @options[:logger_file]
    load_ulrs_data
  end

  def load_ulrs_data()
    @crawled_urls  = File.readlines(@options[:crawled_file]). map(&:chomp)
    @urls_to_crawl = File.readlines(@options[:to_crawl_file]).map(&:chomp)
    dumped_graph = File.read(@options[:graph_file])                    #TODO DRY - new method needed
    @graph  = dumped_graph.empty? ? {} : Marshal.load(dumped_graph)
    dumped_titles = File.read(@options[:titles_file])
    @titles = dumped_titles.empty? ? {} : Marshal.load(dumped_titles)
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

  def get_data
    @db.query{|row| printf("%d %s %s %d\n", row['id'], row['word'], row['url'], row['position'])}
  end

  def crawled?(url)
    @crawled_urls.include? url
  end

  def write_links_to_files
    @urls_to_crawl.uniq!
    @crawled_urls.uniq!
    File.open(@options[:to_crawl_file], "w") do |f|
      @urls_to_crawl.each { |link| f.write "#{link}\n"}
    end
    File.open(@options[:crawled_file], "w") do |f|
      @crawled_urls.each { |link| f.write "#{link}\n"}
    end
    File.open(@options[:graph_file], "w")  { |f| f.write  Marshal.dump(@graph) }
    File.open(@options[:titles_file], "w") { |f| f.write  Marshal.dump(@titles) }
  end

  def process(url_link)
    @urls_to_crawl.unshift url_link
    until @urls_to_crawl.empty? or @count >= @options[:max_urls]
      @urls_to_crawl.each do |url|
        begin
          if @crawler.crawlable? url and not crawled? url
            page   =  @crawler.crawl url
            tokens =  @analyzer.analyze page
            @db.transaction do
              tokens.each { |token| @db.add_word(token.word, token.link, token.position) }
            end
            @count += 1
            p @count
            @titles[url] = page.title
            @graph[url] = page.links #used by PageRank
            @urls_to_crawl += page.links
          end
        rescue URI::InvalidURIError
          @logger.error "Invalid URI link: #{url}"
        rescue OpenURI::HTTPError
          @logger.error "HTTP Error opening: #{url}"
        rescue Exception => e
          @logger.error "Error: #{e} with this: #{url}"
        ensure
          @crawled_urls << url
          @urls_to_crawl.delete url
          write_links_to_files if @count % @options[:max_urls]/10
          break if @count >= @options[:max_urls]
        end
      end
    end
  end
end
begin
  en = Engine.new crawled_file: "crawled.txt", to_crawl_file: "to_crawl.txt", logger_file: "logfile.log",
    graph_file: "graph",titles_file: "titles",  max_urls: 100
  en.init_DB
  # en.process("http://en.wikipedia.com/")
 # en.process("http://google.com/")
  en.process("http://fmi.ruby.bg/")
#  en.get_data
ensure
  en.kill_DB
end
