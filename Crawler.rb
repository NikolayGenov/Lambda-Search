require 'nokogiri'
require 'open-uri'
require 'robots'
require  './Page'

class Crawler
  def initialize(user_agent:'lambda-crawler')
    @user_agent = user_agent
    @robot      = Robots.new @user_agent
  end

  def crawl(url)
    raw_content = open(url,'User-Agent'=> @user_agent, &:read)
    Page.new url: url, content: crawl_content(raw_content),
      links: crawl_links(url, raw_content)
  end

  def crawl_content(content)
    string_content = []

    Nokogiri::HTML(content, 'utf-8').traverse  do |node|
      if node.text? and not node.text =~ /^\s*$/
        string_content << node.content
      end
    end

    string_content
  end

  def crawl_links(url, content)
    Nokogiri::HTML(content, 'utf-8').css('a').map do |node|
      link =  node['href'].to_s
      link =~ URI::regexp ? link : URI::join(url, link).to_s
    end.compact.uniq
  end

  def crawlable? (url)
    urk =~ URI::regexp and @robot.allowed?
  end
end

crawler =  Crawler.new
crawler.crawl("http://fmi.ruby.bg/")
