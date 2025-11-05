task :default do
  puts "There's no default task; either do a convert or a reindex (or both)"
end

task :convert do
  ruby "node2json.rb"
end

task :reindex do
  ruby "import_to_sqlite.rb"
end
