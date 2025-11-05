# Typophile Archive - Hugo Static Site

Static site version of the Typophile typography forum archive (2000-2015).

## Quick Start

### Serve Locally (Fast)

The site is already built in `public/` directory. To serve it:

```bash
# From repository root
./serve.sh

# Or specify custom port
./serve.sh 9000
```

Site will be available at `http://localhost:8080/` (or your custom port).

### Rebuild Site

If you need to rebuild the site from content:

```bash
# From repository root
./build.sh

# Or with fresh export from SQLite
./build.sh --export
```

Build takes approximately 3-4 minutes for 42,270 articles.

## Site Statistics

- **Articles**: 42,270
- **Total Pages**: 51,361
- **Paginator Pages**: 11,608
- **Aliases**: 89,085 (for URL redirects)
- **Site Size**: ~3.5GB
- **Content Size**: 249MB (markdown source)
- **Build Time**: ~3.5 minutes

## Structure

```
hugo-site/
├── content/
│   └── articles/          # 42,270 markdown files
├── layouts/
│   ├── _default/
│   │   ├── baseof.html    # Base template
│   │   ├── list.html      # Article listings
│   │   └── single.html    # Individual articles
│   ├── partials/
│   │   ├── comments.html  # Comment rendering
│   │   └── sidebar.html   # Tag cloud
│   └── taxonomy/
│       └── tag.html       # Tag filtering
├── public/                # Generated static site
└── hugo.toml             # Hugo configuration
```

## Features

- ✅ Article listings with pagination (25 per page)
- ✅ Individual article pages with comments
- ✅ Tag-based filtering and navigation
- ✅ Tag cloud sidebar (tags with 5+ articles)
- ✅ URL aliases for backward compatibility
- ✅ Bootstrap 3 styling (CDN)
- ✅ Full-text search (Pagefind client-side search)

## URL Structure

- Homepage: `/`
- Article: `/[article-id]/` (e.g., `/10/`)
- Pagination: `/page/[n]/` (e.g., `/page/2/`)
- Tag filter: `/tags/[tag-name]/` (e.g., `/tags/typography/`)
- Legacy URLs: Redirect via aliases (`/node/10` → `/10/`)

## Configuration

Edit `hugo.toml` to customize:
- Site URL (`baseURL`)
- Pagination count (`paginate`)
- Taxonomy settings
- Permalink structure

## Deployment

### Option 1: GitHub Pages

1. Push `public/` directory to GitHub
2. Enable GitHub Pages in repository settings
3. Point to `public/` directory

### Option 2: Netlify

1. Connect repository to Netlify
2. Build command: `hugo --minify`
3. Publish directory: `public`

### Option 3: Cloudflare Pages

1. Connect repository to Cloudflare Pages
2. Build command: `hugo --minify`
3. Build output directory: `public`

### Option 4: Static File Host

Upload `public/` directory contents to any static file host:
- Amazon S3 + CloudFront
- Google Cloud Storage
- Azure Static Web Apps
- Any web server (nginx, Apache, Caddy)

## Development

### Hugo Requirements

- Hugo Extended v0.152.2 or later
- Required for: SCSS processing, image processing

### Scripts

- `../build.sh` - Build site from content
- `../build.sh --export` - Export from SQLite and build
- `../serve.sh [port]` - Serve pre-built site locally
- `../export_to_hugo.rb` - Export SQLite to Hugo markdown

### Making Changes

1. Edit content in `content/articles/` (or re-export from database)
2. Edit templates in `layouts/`
3. Edit configuration in `hugo.toml`
4. Rebuild: `../build.sh`
5. Test: `../serve.sh`

**Note**: Do NOT use `hugo server` - it's too slow for 42K+ articles. Use the pre-built site with a simple HTTP server instead.

## Differences from Original Sinatra App

### Features

| Feature | Sinatra | Hugo Static | Status |
|---------|---------|-------------|--------|
| Article listings | ✅ | ✅ | Same |
| Article pages | ✅ | ✅ | Same |
| Comments | ✅ | ✅ | Same |
| Pagination | ✅ | ✅ | Same |
| Tag filtering | ✅ | ✅ | Same |
| Tag counts | ✅ | ✅ | Same |
| Search | ✅ SQLite FTS5 | ✅ Pagefind | Implemented |
| Vote ranking | ✅ | ✅ | Pre-sorted |
| URL structure | `/[id]` | `/[id]/` | Compatible |

### Performance

| Metric | Sinatra | Hugo Static |
|--------|---------|-------------|
| Page load | ~50-200ms | ~5-10ms |
| Search | ~100-500ms | Client-side (fast) |
| Server cost | $5-20/mo | $0 (static) |
| Hosting | VPS/PaaS | CDN/static |
| Build time | N/A | ~7 minutes (Hugo + Pagefind) |

### Architecture

- **Sinatra**: Dynamic server rendering with SQLite database
- **Hugo**: Pre-built static HTML files, no server-side processing
- **Trade-off**: Build time vs. runtime performance

## Next Steps

1. **Add GitHub Actions**: Automated builds and deployment
2. **Deploy to production**: Choose platform (GitHub Pages, Netlify, etc.)
3. **Optimize search index**: Consider reducing index size if needed
4. **Optimize images**: Compress/resize images if needed
5. **Add analytics**: Optional visitor tracking
6. **Custom domain**: Point domain to static site

## License

Archive content belongs to original Typophile community contributors (2000-2015).
