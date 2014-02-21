require 'spec_helper'
describe Lambda_Search::WordRank do

  let (:database_name) { "test" }

  before(:all) do
    @db =  Lambda_Search::Database.new db_name: "test"
    @db.connect
    @db.create_table unless @db.table_exist?
    @db.prepare_insert_statement
    @db.add_word("word" , "third_page"   , 9  )
    @db.add_word("movie", "link_to_page" , 200)
    @db.add_word("maker", "link_to_page" , 5  )
    @db.add_word("maker", "link_to_page" , 10 )
    @db.add_word("maker", "other_page"   , 4  )
    @db.add_word("movie", "other_page"   , 100)
    @db.add_word("short" ,"link_to_page" , 0  )
  end

  after(:all) do
    @db.drop_table
  end

  describe 'get_words_sql' do
    let (:few_words) { ["snake", "shoes"] }
    let (:more_words) { ["ruby", "testing", "is", "awesome"] }
    let (:get_words_ranker1) { Lambda_Search::WordRank.new few_words, database_name }
    let (:get_words_ranker2) { Lambda_Search::WordRank.new more_words, database_name }

    it 'can create valid words sql from 2 words' do
      get_words_ranker1.get_words_sql.should eq "where word = 'snake' or word = 'shoes'"
    end

    it 'can create valid words sql for more words' do
      get_words_ranker2.get_words_sql.
        should eq "where word = 'ruby' or word = 'testing' or word = 'is' or word = 'awesome'"
    end
  end

  describe 'frequency_ranking' do
    let (:freq_ranker) { Lambda_Search::WordRank.new ["maker"], database_name }
    let (:freq_ranker_more_words) { Lambda_Search::WordRank.new ["word", "movie", "maker"], database_name } 
    let (:freq_ranker_no_words_in_db) { Lambda_Search::WordRank.new ["ruby"], database_name }

    it 'can get right frequency ranking for a word' do
      freq_ranker.frequency_ranking.
        should eq ({"link_to_page" => 1.0, "other_page" => 0.5 })
    end

    it 'can get right frequency ranking for a couple of words' do
      freq_ranker_more_words.frequency_ranking.
        should eq ({"link_to_page" => 1.0, "other_page" => 2.0/3, "third_page" => 1.0/3 })
    end

    it 'can get right frequency ranking for no words in db' do
      freq_ranker_no_words_in_db.frequency_ranking.should eq ({})
    end
  end

  describe 'location_ranking' do
    let (:lock_ranker) { Lambda_Search::WordRank.new ["maker"], database_name }
    let (:lock_ranker_more_words) { Lambda_Search::WordRank.new ["word", "movie", "maker"], database_name } 
    let (:lock_ranker_no_words_in_db) { Lambda_Search::WordRank.new ["ruby"], database_name }

    it 'can get location ranking for a word' do
      lock_ranker.location_ranking.
        should eq ({"other_page" => 1.0, "link_to_page" => 5.0/6 })
    end

    it 'can get location ranking for a couple of words' do
      lock_ranker_more_words.location_ranking.
        should eq ({"link_to_page" => 5.0/6 , "other_page" => 1.0, "third_page" => 0.5 })
    end

    it 'can get location ranking for no words in db' do
      lock_ranker_no_words_in_db.location_ranking.should eq ({})
    end
  end

  describe 'get_ratio' do
    let (:ratio_ranker) { Lambda_Search::WordRank.new ["maker","movie","block"], database_name }
    let (:item) { [['maker','movie','movie','block'] ] }
    it 'can get the right ratio' do
      ratio_ranker.get_ratio(item).should eq 5.0 / 3
    end
  end

  describe 'diff_count_ranking' do
    let (:diff_ranker) { Lambda_Search::WordRank.new ["maker","word"], database_name }
    let (:diff_ranker_for_one_search_word) { Lambda_Search::WordRank.new ["ruby"], database_name }

    it 'can get diff count ranking for a couple of wordsd' do
      diff_ranker.diff_count_ranking.
        should eq ({"other_page" => 8.0/9, "link_to_page" => 1.0, "third_page" => 8.0/9 })
    end

    it 'can get diff count ranking for no words in db' do
      diff_ranker_for_one_search_word.diff_count_ranking.should eq ({})
    end
  end

  describe 'merge_rankings' do
    let (:merge_ranker) { Lambda_Search::WordRank.new ["maker","word"], database_name }

    it 'can merge two ranks' do
      merged = merge_ranker.merge_rankings(merge_ranker.frequency_ranking, merge_ranker.location_ranking)
      merged.should_not eq merge_ranker.frequency_ranking
      merged.should_not eq merge_ranker.location_ranking
    end

    it 'can merge all three ranks' do
      merged = merge_ranker.merge_rankings(merge_ranker.frequency_ranking, merge_ranker.location_ranking, merge_ranker.diff_count_ranking)
      merged.should_not eq merge_ranker.frequency_ranking
      merged.should_not eq merge_ranker.location_ranking
      merged.should_not eq merge_ranker.diff_count_ranking
    end
  end

  describe 'rank' do
    let (:ranker) { Lambda_Search::WordRank.new ["maker","word"], database_name }
    it 'can rank words' do
      ranker.rank.should eq ({"link_to_page" => 17.0/6, "other_page" => 43.0/18 , "third_page" => 17.0/9 })
    end
  end
end
