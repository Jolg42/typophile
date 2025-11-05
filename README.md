# typophile.com archive

This repo contains a simple read-only copy of typophile, reconstructed with love.

# Live Site: TODO

**⚠️ Note**: This repository has been converted from Elasticsearch to **SQLite** for easier local development. Elasticsearch has been removed as a dependency.

[Typophile.com](https://en.wikipedia.org/wiki/Typophile_(Internet_forum)) was a fantastic type design web forum started in 2000 that ran until 2015.
It was a cornucopia of type design and font engineering trivia, with threads on every important development in the field in the period.
But it was often overrun with spam, and after 6 months of total shutdown it seems, sadly, not likely to come back any time soon.

In response to the typophile tragedy, during January 2016 Simon Cozens of SILE fame developed a script to download an archive from the [Archive.org Wayback Machine](https://web.archive.org) and Dave Crossland worked with him to convert the raw material into this site. 
See https://github.com/06b/typophile.github.io

I, Joël Galeran, found out about their work and created this fork in November 2025.


## Quick Start (Local Development)

This repository offers two deployment options:

### Option 1: Hugo Static Site (Recommended)

**Best for**: Production deployment, CDN hosting, maximum performance

Pre-built static HTML files ready to serve. No Ruby or database required!

```bash
# Serve the pre-built site (instant startup)
./serve.sh

# Or custom port
./serve.sh 9000
```

Site available at **http://localhost:8080**

**Features**:
- ✅ 51,361 pre-generated HTML pages
- ✅ Instant page loads (~5-10ms)
- ✅ Client-side full-text search (Pagefind)
- ✅ Works with any static host (GitHub Pages, Netlify, S3)
- ✅ Zero server costs

**⚠️ IMPORTANT**: Never use `hugo server` - it's too slow for 42K+ articles (3+ minute builds). Always use `./serve.sh` to serve the pre-built `hugo-site/public/` directory.

See `hugo-site/README.md` for full documentation.

### Option 2: Sinatra Dynamic App (Original)

**Best for**: Local development, dynamic search, testing

Ruby web application with SQLite database.

**Prerequisites**:
- Ruby 3.4+ (managed via rbenv)
- Bundler

**Setup**:
```bash
# 1. Install rbenv (if not already installed)
brew install rbenv ruby-build

# 2. Install Ruby 3.4.7
rbenv install 3.4.7
rbenv local 3.4.7

# 3. Install dependencies
gem install bundler
bundle install

# 4. Import data into SQLite (if typophile.db doesn't exist)
rake reindex

# 5. Start the web server
thin start
```

Site available at **http://localhost:3000**

**Features**:
- ✅ Dynamic full-text search (SQLite FTS5)
- ✅ Real-time tag filtering
- ✅ Popularity-based ranking
- ❌ Requires Ruby server

### Database

- **Database file**: `typophile.db` (227MB, SQLite3)
- **Articles**: 42,270 forum posts with full-text search
- **Search engine**: SQLite FTS5 (full-text search with Porter stemming)
- **Import time**: ~2 minutes for 44K JSON files

**What changed from the original?**
- ❌ **Removed**: Elasticsearch, Java, elasticsearch-fileimport JAR
- ✅ **Added**: SQLite3 (via ruby sqlite3 gem)
- ✅ **Benefit**: Zero external dependencies, single database file, works offline

## Indexing the content

The JSON files in the `json/` directory are imported into a SQLite database:

```bash
# Import all JSON files into typophile.db
rake reindex

# Or run the import script directly
ruby import_to_sqlite.rb
```

This creates a `typophile.db` file with two tables:
- `articles` - Main article data
- `articles_fts` - Full-text search index (FTS5)

## Serving the content

### Sinatra Dynamic App

The Typophile articles are available through a front-end search interface written in [Sinatra](http://www.sinatrarb.com).

```bash
# Start the Sinatra web server
thin start
```

Visit **http://localhost:3000** to browse the archive.

Features:
- Full-text search across articles
- Tag filtering and facets
- Popularity-based ranking
- Pagination (25 results per page)

### Hugo Static Site

For production deployment, use the pre-built Hugo static site:

```bash
# Serve locally (instant startup)
./serve.sh

# Or rebuild from scratch (takes ~3.5 minutes)
./build.sh

# Or rebuild from SQLite database
./build.sh --export
```

Visit **http://localhost:8080** to browse the static site.

**Build Statistics**:
- Articles: 42,270 markdown files
- Generated pages: 51,361 HTML files
- Paginator pages: 11,608
- Aliases: 89,085 (for URL redirects)
- Build time: ~3.5 minutes
- Site size: ~3.5GB

See `hugo-site/README.md` for complete documentation.
