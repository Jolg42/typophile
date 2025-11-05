require 'sqlite3'
require 'redcarpet'
require 'json'

class Comment
  attr_reader :attributes
  @@markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

  def initialize(attributes={})
    @attributes = attributes
  end

  def to_hash
    @attributes
  end

  def content
    @attributes["content"]
  end

  def content_html
    @@markdown.render(content)
  end

  def time
    @attributes["time"]
  end

  def author
    @attributes["author"]
  end
end

class Article
  attr_reader :attributes
  @@markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

  def initialize(attributes={})
    @attributes = attributes
  end

  def to_hash
    @attributes
  end

  def content
    @attributes["content"]
  end

  def content_html
    @@markdown.render(content || "")
  end

  def tags
    tags_str = @attributes["tags"]
    return [] unless tags_str
    return tags_str if tags_str.is_a?(Array)
    JSON.parse(tags_str) rescue []
  end

  def time
    @attributes["time"]
  end

  def author
    @attributes["author"]
  end

  def id
    @attributes["id"]
  end

  def title
    @attributes["title"]
  end

  def comments
    comments_str = @attributes["comments"]
    return [] unless comments_str
    comments_data = comments_str.is_a?(String) ? JSON.parse(comments_str) : comments_str
    comments_data.map {|e| Comment.new(e) }
  rescue
    []
  end

  def votes
    @attributes["votes"] || 0
  end
end

class SearchResults
  attr_reader :articles, :total, :aggregations

  def initialize(articles, total, aggregations = {})
    @articles = articles
    @total = total
    @aggregations = aggregations
  end

  def first
    @articles.first
  end

  def each(&block)
    @articles.each(&block)
  end

  def each_with_hit(&block)
    # Elasticsearch compatibility: yields article and a fake hit object
    @articles.each do |article|
      hit = {'highlight' => {}}
      block.call(article, hit)
    end
  end

  def empty?
    @articles.empty?
  end

  def size
    @articles.size
  end
end

class ArticleRepository
  DB_PATH = 'typophile.db'

  def initialize(options={})
    @db = SQLite3::Database.new(options[:db_path] || DB_PATH)
    @db.results_as_hash = true
    create_tables!
  end

  def create_tables!
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS articles (
        id INTEGER PRIMARY KEY,
        title TEXT,
        content TEXT,
        author TEXT,
        time TEXT,
        forum TEXT,
        tags TEXT,
        uid INTEGER,
        votes INTEGER DEFAULT 0,
        comments TEXT
      );
    SQL

    @db.execute <<-SQL
      CREATE INDEX IF NOT EXISTS idx_title ON articles(title);
    SQL

    @db.execute <<-SQL
      CREATE INDEX IF NOT EXISTS idx_author ON articles(author);
    SQL

    @db.execute <<-SQL
      CREATE VIRTUAL TABLE IF NOT EXISTS articles_fts USING fts5(
        id UNINDEXED,
        title,
        content,
        author,
        tags
      );
    SQL
  end

  def save(article_data)
    @db.execute(
      "INSERT OR REPLACE INTO articles (id, title, content, author, time, forum, tags, uid, votes, comments) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [
        article_data['id'],
        article_data['title'],
        article_data['content'],
        article_data['author'],
        article_data['time'],
        article_data['forum'],
        article_data['tags'].to_json,
        article_data['uid'],
        article_data['votes'] || 0,
        article_data['comments'].to_json
      ]
    )

    @db.execute(
      "INSERT OR REPLACE INTO articles_fts (id, title, content, author, tags) VALUES (?, ?, ?, ?, ?)",
      [
        article_data['id'],
        article_data['title'],
        article_data['content'],
        article_data['author'],
        (article_data['tags'] || []).join(' ')
      ]
    )
  end

  def search(options={})
    query = options[:query]
    size = options[:size] || 25
    from = options[:from] || 0

    # Parse query structure
    q_text = nil
    tag_filter = nil
    id_match = nil

    if query.is_a?(Hash)
      # Extract search query from Elasticsearch-style query structure
      if query[:match] && query[:match][:id]
        # Direct ID match: { match: { id: "123" } }
        id_match = query[:match][:id]
      elsif query[:function_score]
        # Function score query: extract the inner query
        inner_query = query[:function_score][:query]
        if inner_query[:match] && inner_query[:match][:_all]
          q_text = inner_query[:match][:_all]
        end
      elsif query[:filtered]
        # Filtered query: { filtered: { query: ..., filter: ... } }
        inner_query = query[:filtered][:query]
        if inner_query[:function_score]
          inner_inner = inner_query[:function_score][:query]
          q_text = inner_inner[:match][:_all] if inner_inner[:match]
        elsif inner_query[:match]
          q_text = inner_query[:match][:_all]
        end
        tag_filter = query[:filtered][:filter][:term][:tags] if query[:filtered][:filter]
      elsif query[:match] && query[:match][:_all]
        # Simple match query: { match: { _all: "search term" } }
        q_text = query[:match][:_all]
      end
    end

    # Fallback: check if q and t were passed directly as options
    q_text ||= options[:q]
    tag_filter ||= options[:t]

    # Build SQL query
    sql_parts = []
    params = []

    if id_match
      # Direct ID lookup
      sql_parts << <<-SQL
        SELECT *,
               (COALESCE(votes, 0) + 1) as score
        FROM articles
        WHERE id = ?
      SQL
      params << id_match
    elsif q_text && !q_text.empty?
      # Use full-text search
      sql_parts << <<-SQL
        SELECT a.*,
               (COALESCE(a.votes, 0) + 1) as score
        FROM articles a
        JOIN articles_fts fts ON a.id = fts.id
        WHERE articles_fts MATCH ?
      SQL
      params << q_text
    else
      # No search query, just list all
      sql_parts << <<-SQL
        SELECT *,
               (COALESCE(votes, 0) + 1) as score
        FROM articles
        WHERE 1=1
      SQL
    end

    # Add tag filter if present
    if tag_filter && !tag_filter.empty?
      sql_parts << "AND tags LIKE ?"
      params << "%#{tag_filter}%"
    end

    # Add ordering by popularity (log score approximation)
    sql_parts << "ORDER BY score DESC"

    # Add pagination
    sql_parts << "LIMIT ? OFFSET ?"
    params << size
    params << from

    sql = sql_parts.join("\n")

    # Execute query
    rows = @db.execute(sql, params)
    articles = rows.map { |row| Article.new(row) }

    # Get total count
    count_sql = if q_text && !q_text.empty?
      "SELECT COUNT(*) as count FROM articles a JOIN articles_fts fts ON a.id = fts.id WHERE articles_fts MATCH ?"
    else
      "SELECT COUNT(*) as count FROM articles WHERE 1=1"
    end

    count_params = []
    count_params << q_text if q_text && !q_text.empty?

    if tag_filter && !tag_filter.empty?
      count_sql += " AND tags LIKE ?"
      count_params << "%#{tag_filter}%"
    end

    total = @db.execute(count_sql, count_params).first['count']

    # Get tag aggregations
    tag_counts = {}
    if !tag_filter || tag_filter.empty?
      # Only compute aggregations if not filtered
      all_rows = @db.execute("SELECT tags FROM articles")
      all_rows.each do |row|
        tags = JSON.parse(row['tags']) rescue []
        tags.each do |tag|
          tag_counts[tag] ||= 0
          tag_counts[tag] += 1
        end
      end
    end

    aggregations = {
      'tags' => {
        'buckets' => tag_counts.map { |k, v| {'key' => k, 'doc_count' => v} }
                               .sort_by { |b| -b['doc_count'] }
                               .take(20)
      }
    }

    SearchResults.new(articles, total, aggregations)
  end

  def self.create_index!(options={})
    # This method is called during reindex, but with SQLite we just ensure tables exist
    repo = new(options)
    puts "SQLite database initialized at #{DB_PATH}"
  end

  def close
    @db.close if @db
  end
end
