require 'unicode'

class Page
  attr_reader :content, :url, :links

  def initialize(url:,content: nil, links: nil)
    @content = minimize_content content
    @url, @links = url, links
  end

  def marshal_dump
    [@url, @content, @links]
  end

  def marshal_load(data_array)
    @url, @content, @links = data_array
  end

  private

  def minimize_content(content)
    content.map do |element|
      Unicode.downcase(element).strip.gsub(/[^[[:alnum:]]\s]/, '').split(" ")
    end.reject(&:empty?).flatten(1)
  end
end
