class Page
  attr_reader :content, :title, :url, :links

  def initialize(url:, title: nil, content: nil, links: nil)
    @content, @url, @title, @links =  content ,url, title, links
  end

  def marshal_dump
    [@url, @title, @content, @links]
  end

  def marshal_load(data_array)
    @url, @title, @content, @links = data_array
  end
end
