class PageRank

  DAMPING_FACTOR = 0.8
  NUMBER_LOOPS = 10

  def initialize(graph_file:,page_ranks_file:)
    dumped_graph =  File.read graph_file
    @graph = Marshal.load dumped_graph
    @number_pages = @graph.size
    @page_ranks_file = page_ranks_file
    @ranks = {}
  end


  def compute_ranks
    @graph.keys.each { |url| @ranks[url] = 1.0 / @number_pages }

    0.upto(NUMBER_LOOPS) {  @ranks =  get_new_hash_ranks }

    save_to_file @ranks
  end

  def get_new_rank(page)
    newrank = (1 - DAMPING_FACTOR) / @number_pages

    @graph.values.each do |node|
      if node.include? page
        newrank += DAMPING_FACTOR * (@ranks[page] / node.size)
      end
    end

    newrank
  end

  def get_new_hash_ranks
    newranks = {}

    @graph.keys.each { |page| newranks[page] = get_new_rank page }

    newranks
  end

  def save_to_file(ranks)
    File.open(@page_ranks_file, "w") { |f| f.write Marshal.dump(ranks) }
  end

end

ran = PageRank.new graph_file: "graph", page_ranks_file: "ranks"
p ran.compute_ranks
