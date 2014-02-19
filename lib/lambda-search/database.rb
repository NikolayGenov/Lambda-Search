require 'pg'

module Lambda_Search
  class PostgresDirect
    def initialize(db_name:)
      @db_name = db_name
    end

    def connect
      @conn = PG.connect(:dbname => @db_name)
    end

    def create_table
      @conn.exec("CREATE TABLE words (id serial NOT NULL, word character varying(255), url character varying(255),position integer, CONSTRAINT words_pkey PRIMARY KEY (id)) WITH (OIDS=FALSE);");
    end

    def drop_table
      @conn.exec("DROP TABLE words")
    end

    def prepare_insert_statement
      @conn.prepare("insert_word", "insert into words (word, url, position) values ($1, $2, $3)")
    end

    def add_word(word, url, position)
      @conn.exec_prepared("insert_word", [word, url, position])
    end

    def transaction(&block)
      @conn.transaction { yield }
    end

    def query(arguments = "")
      @conn.exec( "SELECT * FROM words #{arguments}") do |result|
        result.each do |row|
          yield row if block_given?
        end
      end
    end

    def query_select(what, arguments = "")
      @conn.exec( "SELECT #{what} FROM words #{arguments}") do |result|
        result.each do |row|
          yield row if block_given?
        end
      end
    end
    def disconnect
      @conn.close
    end
  end
end
