class Issue < ActiveRecord::Base
  TITLE_OF_ASK_PARTI = 'Ask Parti'
  SLUG_OF_ASK_PARTI = 'ask-parti'
  OF_ALL = RecursiveOpenStruct.new({
    is_all?: true, title: '모든 이슈',
    slug: 'all',
    posts: Post.all,
    articles: Article.all,
    opinions: Opinion.all,
    watches: User.all,
    logo: {file: true}, logo_url: 'all_issue_logo.png',
    cover: {file: nil}})

  has_many :relateds
  has_many :related_issues, through: :relateds, source: :target
  has_many :posts
  has_many :articles, through: :posts, source: :postable, source_type: Article
  has_many :opinions, through: :posts, source: :postable, source_type: Opinion
  has_many :questions, through: :posts, source: :postable, source_type: Question
  has_many :discussions, through: :posts, source: :postable, source_type: Discussion
  has_many :watches

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  mount_uploader :logo, ImageUploader
  mount_uploader :cover, ImageUploader

  def watched_by? someone
    watches.exists? user: someone
  end

  def is_all?
    false
  end

  def set_slug
    return if self.title.blank?
    self.slug = self.title.strip.downcase.gsub(/\s+/, "-")
  end
end
