#!/usr/bin/env ruby
require './models/article.rb'
require 'json'

puts "Initializing SQLite database..."
repo = ArticleRepository.new

puts "Importing JSON files from json/ directory..."
count = 0
errors = 0

Dir.glob("json/*.json").each do |file|
  begin
    data = JSON.parse(File.read(file))
    repo.save(data)
    count += 1
    puts "Imported #{count} articles..." if count % 1000 == 0
  rescue => e
    errors += 1
    puts "Error importing #{file}: #{e.message}" if errors < 10
  end
end

puts "\nImport complete!"
puts "Successfully imported: #{count} articles"
puts "Errors: #{errors}" if errors > 0

repo.close
