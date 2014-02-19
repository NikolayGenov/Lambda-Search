require 'digger'
require 'sinatra'

get '/' do
  erb :search
end

post '/search' do
  digger = Digger.new page_rank_file: "ranks", titles_file:"titles", max_results: 20
  time_start = Time.now
  @results = digger.search(params[:input])
  time_end = Time.now
  @time_taken = "#{'%6.2f' % (time_end - time_start)} secs"
  erb :search
end
