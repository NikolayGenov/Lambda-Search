require 'pg'


class PostgresDirect
  # Create the connection instance.
  def connect
    @conn = PG.connect(
      :dbname => 'Lam')
  end

  # Create our test table (assumes it doesn't already exist)
  def createWordTable
      @conn.exec("CREATE TABLE words (id serial NOT NULL, word character varying(255), url character varying(255),position integer, CONSTRAINT words_pkey PRIMARY KEY (id)) WITH (OIDS=FALSE);");
  end

  # When we're done, we're going to drop our test table.
  def dropWordTable
    @conn.exec("DROP TABLE words")
  end

  # Prepared statements prevent SQL injection attacks.  However, for the connection, the prepared statements
  # live and apparently cannot be removed, at least not very easily.  There is apparently a significant
  # performance improvement using prepared statements.
  def prepareInsertWordStatement
    @conn.prepare("insert_word", "insert into words (id, word, url, position) values ($1, $2, $3, $4)")
  end

  # Add a user with the prepared statement.
  def addWord(id, word, url, position)
    @conn.exec_prepared("insert_word", [id, word, url, position])
  end

  # Get our data back
  def queryWordTable
    @conn.exec( "SELECT * FROM words") do |result|
      result.each do |row|
        yield row if block_given?
      end
    end
  end

  # Disconnect the back-end connection.
  def disconnect
    @conn.close
  end
end
