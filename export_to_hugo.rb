#!/usr/bin/env ruby
require 'sqlite3'
require 'json'
require 'fileutils'
require 'yaml'

class HugoExporter
  DB_PATH = 'typophile.db'
  OUTPUT_DIR = 'hugo-site/content/articles'

  def initialize(limit: nil)
    @db = SQLite3::Database.new(DB_PATH)
    @db.results_as_hash = true
    @limit = limit
    @exported_count = 0
    @error_count = 0
  end

  def export_all
    puts "Exporting articles to Hugo format..."
    puts "Output directory: #{OUTPUT_DIR}"

    # Create output directory
    FileUtils.mkdir_p(OUTPUT_DIR)

    # Get total count
    total_query = "SELECT COUNT(*) as count FROM articles"
    total = @db.execute(total_query).first['count']
    total = [@limit, total].compact.min

    puts "Total articles to export: #{total}"

    # Fetch articles
    query = "SELECT * FROM articles ORDER BY id"
    query += " LIMIT #{@limit}" if @limit

    @db.execute(query) do |row|
      export_article(row)

      if @exported_count % 1000 == 0
        puts "Exported #{@exported_count} articles..."
      end
    end

    puts "\nExport complete!"
    puts "Successfully exported: #{@exported_count} articles"
    puts "Errors: #{@error_count}"
  end

  def export_article(row)
    begin
      article_id = row['id']

      # Parse JSON fields
      tags = parse_json_field(row['tags']) || []
      comments = parse_json_field(row['comments']) || []

      # Build front matter
      front_matter = {
        'title' => row['title'] || "Untitled",
        'date' => parse_date(row['time']),
        'author' => row['author'] || "Unknown",
        'tags' => tags,
        'votes' => row['votes'] || 0,
        'forum' => row['forum'],
        'draft' => false
      }

      # Add aliases for URL preservation
      front_matter['aliases'] = [
        "/#{article_id}",
        "/node/#{article_id}"
      ]

      # Store comments as JSON in front matter to avoid YAML escaping issues
      comments_json = nil
      if comments.any?
        comments_json = comments.map do |c|
          {
            'author' => c['author'] || '',
            'time' => c['time'] || '',
            'content' => (c['content'] || '').gsub("\n", ' ').strip
          }
        end.to_json
      end

      # Build markdown file content
      content = []
      content << "---"

      # Write front matter manually to avoid YAML indentation issues
      content << "title: #{front_matter['title'].to_json}"
      content << "date: #{front_matter['date'].to_json}"
      content << "author: #{front_matter['author'].to_json}"
      content << "tags: #{front_matter['tags'].to_json}"
      content << "votes: #{front_matter['votes']}"
      content << "forum: #{front_matter['forum'].to_json}"
      content << "draft: false"
      content << "aliases: #{front_matter['aliases'].to_json}"
      content << "comments_json: #{comments_json.to_json}" if comments_json
      content << "---"
      content << ""
      content << (row['content'] || "")

      # Write file
      filename = "#{OUTPUT_DIR}/#{article_id}.md"
      File.write(filename, content.join("\n"))

      @exported_count += 1
    rescue => e
      @error_count += 1
      puts "Error exporting article #{row['id']}: #{e.message}"
    end
  end

  def parse_json_field(field)
    return [] if field.nil? || field.empty?
    return field if field.is_a?(Array)
    JSON.parse(field)
  rescue JSON::ParserError
    []
  end

  def parse_date(time_str)
    return Time.now.iso8601 if time_str.nil? || time_str.empty?

    # Try to parse the date string
    # Format from the archive is likely: "June 1, 2015 - 12:00pm"
    begin
      require 'time'
      Time.parse(time_str).iso8601
    rescue
      # If parsing fails, use a default date
      Time.now.iso8601
    end
  end

  def close
    @db.close if @db
  end
end

# Run the exporter
if __FILE__ == $0
  # Check for limit argument
  limit = ARGV[0]&.to_i

  if limit && limit > 0
    puts "Running in test mode: exporting #{limit} articles"
  end

  exporter = HugoExporter.new(limit: limit)
  exporter.export_all
  exporter.close
end
