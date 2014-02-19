module Lambda_Search
  module Utilities
    def load_marshal_hash(file_name)
      file = File.read(file_name)
      file.empty? ? {} : Marshal.load(file)
    end

    def frequencies(array)
      array.each_with_object Hash.new(0) do |value, result|
        result[value] += 1
      end
    end

    def read_text_lines(file_name)
      File.readlines(file_name).map(&:chomp)
    end

    def write_text_lines(file_name, object)
      object.uniq!
      File.open(file_name, "w") do |f|
        object.each { |data| f.write "#{data}\n"}
      end
    end

    def marshal_dump_to_file(file_name, object)
      File.open(file_name, "w") { |f| f.write Marshal.dump(object) }
    end
  end
end
