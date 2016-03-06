SitemapGenerator::Sitemap.default_host = "http://parti.xyz"
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'
SitemapGenerator::Sitemap.create do
  Issue.find_each do |issue|
    add slug_issue_path(slug: issue.slug), changefreq: 'daily', lastmod: issue.posts.newest.try(:updated_at) || issue.updated_at
  end
end
