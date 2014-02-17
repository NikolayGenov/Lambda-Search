require 'pg'

class PostgresDirect
  def connect
    @conn = PG.connect(
      :dbname => 'Lam')
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

  def query_table
    @conn.exec( "SELECT * FROM words") do |result|
      result.each do |row|
        yield row if block_given?
      end
    end
  end

  def disconnect
    @conn.close
  end
end