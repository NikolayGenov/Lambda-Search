class Page
  attr_reader :content, :url, :links

  def initialize(url:,content: nil, links: nil)
    @url, @content, @links = url, content, links
  end

  def marshal_dump
    [@url, @content, @links]
  end

  def marshal_load(data_array)
    @url, @content, @links = data_array
  end
end
