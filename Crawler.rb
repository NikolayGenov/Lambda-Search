require 'nokogiri'
require 'open-uri'
require 'robots'
require 'stemmer'
require  './Page'

class Crawler
  def initialize(user_agent:'lambda-crawler')
    @user_agent = user_agent
    @robot      = Robots.new @user_agent
  end

  def crawl(url)
    raw_content = open(url,'User-Agent'=> @user_agent, &:read)
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
    urk =~ URI::regexp and @robot.allowed?
  end
end

crawler =  Crawler.new
page = crawler.crawl("http://en.wikipedia.com/")
p page.content
