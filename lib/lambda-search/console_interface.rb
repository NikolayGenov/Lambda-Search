require 'digger'

digger = Digger.new page_rank_file: "ranks", titles_file:"titles", max_results: 20
time_start = Time.now
puts "Enter search phrase"
@results = digger.search(gets.chomp)
time_end = Time.now
@time_taken = "#{'%6.2f' % (time_end - time_start)} secs"
@results.each_with_index do |object,index|

  printf("%02d. Title: '%s' \t Link: %s\n",index,object.last,object.first)
end
