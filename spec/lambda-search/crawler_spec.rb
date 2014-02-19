require 'spec_helper'
describe Lambda_Search::Crawler do

  let :crawler do
    Lambda_Search::Crawler.new user_agent: "lambda-search"
  end

  let(:link) { "http://somelink.com" }
  let(:simple_link) { "http://link.com" }
  let :content  do <<-HTML
<html>
  <head>
    <title>Some Title</title>
  </head>
  <body>
    <p>Some text with <a href="http://link.com">link</a></p>
  </body>
</html>
  HTML
  end
  describe 'is_valid_url?' do
    def valid(url)
      crawler.is_valid_url?(url).should eq true
    end

    def invalid(url)
      crawler.is_valid_url?(url).should eq false
    end

    it 'can recognize valid url' do
      valid "http://google.com"
      valid "http://fmi.ruby.bg"
      valid "http://fmi.golang.bg/announcements?page=2"
    end

    it 'can recognize valid url secure' do
      valid "https://github.com/"
    end

    it 'can recognize invalid url' do
      invalid "/wiki/Help:IPA_for_English"
      invalid "Doc~E7A20980B9C0D46E99A9F60BC09506343~ATpl~Ecommon~Scontent.html"
      invalid "//en.wikipedia.org/w/index.php?title=Template:Wikipedias&action=edit"
    end
  end

  describe 'crawlable?' do
    WebMock.allow_net_connect!
    def crawlable(url)
      crawler.crawlable?(url).should eq true
    end

    def not_crawlable(url)
      crawler.crawlable?(url).should eq false
    end

    it 'can recognize crawlable urls' do
      crawlable "http://en.wikipedia.org/wiki/Ruby"
      crawlable "https://www.cia.gov/library/publications/the-world-factbook/geos/gl.html"
    end

    it 'can recognize NOT crawlable formats in the urls' do
      not_crawlable "http://www.michigan.gov/documents/deq/OFR_57_Leverett_NB294_306670_7.pdf"
      not_crawlable "http://gorstat.kiev.ua/Docs/2820.doc"
      not_crawlable "http://fmi.ruby.bg/system/rubyinstaller-2.1.0-r.exe"
    end

    it 'can recognize other not pages links - mails, js, etc' do
      not_crawlable "mailto:gnu@gnu.org"
      not_crawlable "javascript:addto(2);logonmyt('Shared',navmsid,'Facebook');log('sh_fb','');"
      not_crawlable "http://economictimes.indiatimes.com/articleshow/29094246.cms#write"
      not_crawlable "http://economictimes.indiatimes.com/currentquote.cms?ticker=a"
    end
  end

  describe 'get_title' do

    let :utf_title do <<-HTML_UTF
      <html>
        <head>
          <title>Някакво заглавие</title>
        </head>
      </html>
    HTML_UTF
    end

    let :head_text do <<-HTML
      <html>
        <head>
          Някакво заглавие
        </head>
      </html>
    HTML
    end

    it "can get title correctly" do
      crawler.get_title(content).should eq "Some Title"
    end

    it "can get utf-8 title correctly" do
      crawler.get_title(utf_title).should eq "Някакво заглавие"
    end

    it "cannot get head text for a title" do
      crawler.get_title(head_text).should eq nil
    end
  end

  describe 'get_links' do
    let(:simple_link_2) { "http://otherlink.com" }
    let(:sublink) { "http://link.com/other_page" }
    let :multi_link_content  do <<-HTML
      <html>
        <body>
          <p>Some text with <a href="http://link.com">link</a></p>
          <p>Some other text with <a href="http://otherlink.com">another</a></p>
        </body>
      </html>
    HTML
    end

    let :sublinks do <<-HTML
      <html>
        <body>
          <p>Some other text with <a href="/other_page">another</a></p>
        </body>
      </html>
    HTML
    end

    it 'can get simple link from a page' do
      crawler.get_links(link,content).should eq [simple_link]
    end

    it 'can get multiple links' do
      crawler.get_links(link, multi_link_content) =~ [simple_link, simple_link_2]
    end

    it 'can join one link to its sublink' do
      crawler.get_links(simple_link, sublinks).should eq [sublink]
    end
  end

  describe 'get_content'  do
    let :fancy_content  do <<-HTML
    <html>
      <body>
       <p>Яко фенси контент<a href="http://link.com"> нали?</a></p>
       <div>Тука</div> <h1>Има</h1>
      </body>
    </html>
    HTML
    end

    it 'can get some content' do
      crawler.get_content(content).should eq ["Some Title","Some text with ", "link"]
    end

    it 'can get utf-u content from multiple tags' do
      crawler.get_content(fancy_content).should eq ["Яко фенси контент", " нали?", "Тука", "Има"]
    end
  end

  describe 'crawl' do
    before(:each) do
      stub_request(:any, link).to_return(:status => 200, :body => content )
    end
    it 'can crawl simple page' do
      crawler.crawl(link) do |page|
        page.should equal Lambda_Search::Objects::Page.new url: link,title: 'Some Title',
          content: ["Some Title","Some text with ", "link"], links: [simple_link]
      end
    end

    #TODO add more
  end
end
