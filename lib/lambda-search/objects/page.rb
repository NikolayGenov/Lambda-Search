module Lambda_Search
  module Objects
    class Page
      attr_reader :content, :title, :url, :links

      def initialize(url:, title: nil, content: nil, links: nil)
        @content, @url, @title, @links =  content ,url, title, links
      end
    end
  end
end
