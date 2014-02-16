require 'nokogiri'
require 'open-uri'
require 'robots'
require 'stemmer'
require  './Page'
require  'open_uri_redirections'

DO_NOT_CRAWL_TYPES = %w(.pdf mobi epub .doc .xls .ppt .exe .mp3 .m4v .avi .mpg .rss .xml .json .txt .git .zip .md5 .asc .jpg .gif .png .jpeg)

class Crawler
  def initialize(user_agent:'lambda-crawler')
    @user_agent = user_agent
    @robot      = Robots.new @user_agent
  end

  def crawl(url)
    raw_content = open(url,'User-Agent'=> @user_agent, :allow_redirections => :all, &:read)
    Page.new url: url, content: get_content(raw_content),
      links: get_links(url, raw_content), title: get_title(raw_content)
  end

  def get_content(content)
    string_content = []

    Nokogiri::HTML(content, 'utf-8').traverse  do |node|
      if node.text? and not node.text =~ /^\s*$/
        string_content << node.content
      end
    end

    string_content
  end

  def get_links(url, content)
    Nokogiri::HTML(content, 'utf-8').css('a').map do |node|
      link =  node['href'].to_s
      link =~ URI::regexp ? link : URI::join(url, link).to_s
    end.compact.uniq
  end

  def get_title(content)
    Nokogiri::HTML(content, 'utf-8').title
  end

  def crawlable? (url)
    return false if DO_NOT_CRAWL_TYPES.include? url[(url.size-4)..url.size] or url.include? '?' or url.include? '/cgi-bin/' or url.include? '&amp;' or url[0..9] == 'javascript' or url[0..5] == 'mailto' or url.include? '#'
   is_valid_url?(url) and @robot.allowed? url
  end

  def is_valid_url?(url)
    uri = URI.parse url
    uri.kind_of? URI::HTTP
  rescue URI::InvalidURIError
    false
  end
end
#crawler =  Crawler.new
# TEST crawler.is_valid_url?("/wiki/Wikipedia:Please_clarify")
#page = crawler.crawl("http://en.wikipedia.com/")
#p page.content
