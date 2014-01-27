require 'unicode'

class Page
  attr_reader :content, :title, :url, :links

  def initialize(url:, title: nil, content: nil, links: nil)
    @content = minimize_content content
    @url, @title, @links = url, title, links
  end

  def marshal_dump
    [@url, @title, @content, @links]
  end

  def marshal_load(data_array)
    @url, @title, @content, @links = data_array
  end

  private

  def minimize_content(content)
    content.map do |element|
      Unicode.downcase(element).strip.gsub(/[^[[:alnum:]]\s]/, '').split(" ")
    end.reject(&:empty?).flatten
  end
end
