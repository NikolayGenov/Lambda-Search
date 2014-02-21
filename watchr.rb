watch('spec/lambda-search/crawler_spec.rb')    { |md| system "rspec spec/lambda-search/crawler_spec.rb    --require ./lib/lambda-search/crawler.rb   --colour --format documentation"}
watch('spec/lambda-search/analyzer_spec.rb')   { |md| system "rspec spec/lambda-search/analyzer_spec.rb   --require ./lib/lambda-search/analyzer.rb  --colour --format documentation"}
watch('spec/lambda-search/page_rank_spec.rb')  { |md| system "rspec spec/lambda-search/page_rank_spec.rb  --require ./lib/lambda-search/page_rank.rb --colour --format documentation"}
watch('spec/lambda-search/word_rank_spec.rb')  { |md| system "rspec spec/lambda-search/word_rank_spec.rb  --require ./lib/lambda-search/word_rank.rb --colour --format documentation"}
watch('spec/lambda-search/engine_spec.rb')     { |md| system "rspec spec/lambda-search/engine_spec.rb     --require ./lib/lambda-search/engine.rb    --colour --format documentation"}
