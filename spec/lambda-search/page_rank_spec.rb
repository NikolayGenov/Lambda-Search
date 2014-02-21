require 'spec_helper'
describe Lambda_Search::PageRank do

  let :ranker do
    Lambda_Search::PageRank.new graph_file: "graph_test", page_rank_file:  "rank_test"
  end
  let :graph_hash do
    {'http://page.com/sub/urank/arsenic.html'=> ['http://page.com/sub/urank/nickel.html'],
     'http://page.com/sub/urank/zinc.html'=> ['http://page.com/sub/urank/nickel.html', 'http://page.com/sub/urank/arsenic.html'],
     'http://page.com/sub/urank/hummus.html'=> [],
     'http://page.com/sub/urank/nickel.html'=> ['http://page.com/sub/urank/kathleen.html'],
     'http://page.com/sub/urank/index.html'=> ['http://page.com/sub/urank/hummus.html', 'http://page.com/sub/urank/arsenic.html', 'http://page.com/sub/urank/kathleen.html', 'http://page.com/sub/urank/nickel.html', 'http://page.com/sub/urank/zinc.html'],
     'http://page.com/sub/urank/kathleen.html'=> []}
  end

  let :hash_ranks do
    {"http://page.com/sub/urank/arsenic.html" => 0.12666666666666665,
     "http://page.com/sub/urank/hummus.html" => 0.06,
     "http://page.com/sub/urank/index.html" => 0.033333333333333326,
     "http://page.com/sub/urank/kathleen.html" => 0.19333333333333333,
     "http://page.com/sub/urank/nickel.html" => 0.26,
     "http://page.com/sub/urank/zinc.html" => 0.06,
    }
  end

  let :valid_ranks do
    {"http://page.com/sub/urank/zinc.html"     => 0.038666666666666655,
     "http://page.com/sub/urank/arsenic.html"  => 0.0760333080203904,
     "http://page.com/sub/urank/hummus.html"   => 0.039682541078744915,
     "http://page.com/sub/urank/index.html"    => 0.033333333333333326,
     "http://page.com/sub/urank/kathleen.html" => 0.39011157600566604,
     "http://page.com/sub/urank/nickel.html"   => 5.5194810277358854,
     "http://page.com/sub/urank/zinc.html"     => 0.039682541078744915 }
  end

  describe 'get_new_rank' do
    let (:page) { 'http://page.com/sub/urank/nickel.html' }
    let (:page_2) { 'http://page.com/sub/urank/index.html' }
    let (:page_3) { 'http://page.com/sub/urank/hummus.html' }

    it 'can get new positive page rank' do
      ranker.get_new_rank(page).should eq 0.26
    end

    it 'can get new positive rank for another page' do
      ranker.get_new_rank(page_2).should be < 0.4
    end

    it 'can get rank for page with no outlinks' do
      ranker.get_new_rank(page_3).should eq 0.06
    end
  end

  describe 'change of ranks' do
    it 'can calculate all new hash ranks' do
      ranker.get_new_hash_ranks.should eq hash_ranks
    end

    it 'changes the ranks again and they are different after another loop' do
      ranker.calculate_ranks(1)
      ranker.get_new_hash_ranks.should_not eq hash_ranks
    end

    it 'changes ranks after 10 loops' do
      ranker.calculate_ranks(5)
      first_results = ranker.get_new_hash_ranks
      ranker.calculate_ranks(5)
      second_results = ranker.get_new_hash_ranks
      first_results.should_not eq second_results
      hash_ranks.should_not eq second_results
    end
  end

  describe 'calculate valid ranks' do
    it 'can calculate valid ranks for 10 loops' do
      ranker.calculate_ranks(10).should eq valid_ranks
    end
  end

  describe 'save ranks to file' do
    it 'can save file to file with marshal dump' do
      ranker.save_ranks
      hashes = ranker.load_marshal_hash("rank_test")
      hashes.should eq valid_ranks
    end
  end
end
