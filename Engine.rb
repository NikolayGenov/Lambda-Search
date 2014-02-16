require './Crawler'
require './Analyzer'
require './Token_Storer'
class Engine
  def initialize(options = {})
    @options = options
    @crawled_urls = File.readlines("crawled.txt").map(&:chomp)
    @crawler = Crawler.new
    @analyzer = Analyzer.new
    @db = PostgresDirect.new
    @cnt = 1
    @urls_to_crawl = File.readlines("to_crawl.txt").map(&:chomp)
  end

  def init_DB
    @db.connect
    @db.createWordTable
    @db.prepareInsertWordStatement
  end

  def kill_DB
    @db.dropWordTable
    @db.disconnect
  end

  def get_data
    @db.queryWordTable {|row| printf("%d %s %s %d\n", row['id'], row['word'], row['url'], row['position'])}
  end

  def crawled?(url)
    @crawled_urls.include? url
  end

  def write_links_to_files
    @urls_to_crawl.uniq!
    @crawled_urls.uniq!
    File.open("to_crawl.txt", "w") do |f|
      @urls_to_crawl.each { |link| f.write "#{link}\n"}
    end
    File.open("crawled.txt", "w") do |f|
      @crawled_urls.each { |link| f.write "#{link}\n"}
    end
  end

  def process(url_link)
    # @urls_to_crawl.unshift(url_link)
    until @urls_to_crawl.empty?
      @urls_to_crawl.each do |url|
        begin
          if @crawler.crawlable? url and not crawled? url 
            p url
            page =   @crawler.crawl url
            tokens =  @analyzer.analyze page
            # tokens.each do |token| 
            # @db.addWord(@cnt,token.word,token.link,token.position);
            @cnt +=1
            # end
            p @cnt
            @urls_to_crawl += page.links
          end
          write_links_to_files if @cnt % 100 == 0
        rescue URI::InvalidURIError
          puts "invalid link"
        rescue OpenURI::HTTPError
          puts "PAGE NOT FOUND" #TODO log that
        rescue Errno::ECONNREFUSED
          puts "Refured connection"
        rescue SocketError
          puts "SocketError"
        rescue RuntimeError
          puts "Something bad happened"
        ensure
          @crawled_urls << url
          @urls_to_crawl.delete(url)
        end
      end
    end
  end

end
begin
  en = Engine.new
  en.init_DB
  # en.process("http://en.wikipedia.com/")
  # en.process("http://google.com/")
  en.process("http://fmi.ruby.bg/")
  en.get_data
ensure
  en.kill_DB
end
