require 'spec_helper'
describe Lambda_Search::Analyzer do

  let :analyzer do
    Lambda_Search::Analyzer
  end

  let :content_massive do
    ["Translations ", " ", "Millions of people use Ubuntu around the globe. They speak hundreds of different languages and it’s our mission to
   make Ubuntu as easily accessible to everyone as possible." ]
  end

  describe 'stem words' do
    let (:verbs) { ["singing", "coding", "eating"] }
    let (:content) { ["ruby", "teaching", "vegetables"] }

    it 'get stem for verbs' do
      analyzer.stem_words(verbs).
        should eq ["sing", "code", "eat"]
    end

    it 'get stem for other words' do
      analyzer.stem_words(content).
        should eq ["rubi", "teach", "veget"]
    end
  end

  describe 'remove_stopwords' do
    let (:some_stopwords) { ["about", "the", "all" ,"rabbit", "went", "if"] }
    let (:other_stopwords) { ["are", "as", "every" ,"person", "here", "indeed"] }

    it 'can remove simple stop words' do
      analyzer.remove_stopwords(some_stopwords).
        should eq ["rabbit", "went"]
    end

    it 'can remove other stop words' do
      analyzer.remove_stopwords(other_stopwords).
        should eq ["person"]
    end
  end

  describe 'extract_words' do

    let :extracted_words do
      ["translations", "millions", "of", "people",
       "use", "ubuntu", "around", "the", "globe", "they", "speak",
       "hundreds", "of", "different", "languages", "and", "its",
       "our", "mission", "to", "make", "ubuntu", "as", "easily",
       "accessible", "to", "everyone", "as", "possible"]
    end

    it 'can extract massive content' do
      analyzer.extract_words(content_massive).
        should eq extracted_words
    end

    it 'can extract utf-8 words' do
      analyzer.extract_words(["君が代", "гошо", "\n"]).
        should eq ["君が代", "гошо"]
    end
  end

  describe 'keywords_position_pairs' do
    let (:simple_content) { ["person", "word", "laptop"] }

    it 'can get valid key position pairs' do
      analyzer.keywords_position_pairs(simple_content).
        should eq [["person", 0], ["word", 1], ["laptop", 2]]
    end
  end

  describe 'get_words' do
    it 'can process words' do
      analyzer.get_words(content_massive) =~
      ["translat", "million", "peopl", "us", "ubuntu", "globe", "speak",
       "hundr", "differ", "languag", "mission", "make", "ubuntu", "easili ", "access", "possibl"]
    end
  end

  describe 'analyze' do
    #TODO add page
  end


end


