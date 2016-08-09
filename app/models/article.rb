class Article < ActiveRecord::Base
  include UniqueSoftDeletable
  include Postable
  acts_as_unique_paranoid
  acts_as :post, as: :postable

  belongs_to :source, polymorphic: true
  accepts_nested_attributes_for :source

  validates :source, presence: true
  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :visible, -> { where(hidden: false) }
  scope :previous_of_article, ->(article) { where('articles.created_at < ?', article.created_at) if article.present? }

  def specific_origin
    self
  end

  def title
    return '' if self.hidden?
    source.try(:title) || source.try(:url)
  end

  def source_body
    return '' if self.hidden?
    source.try(:body)
  end

  def site_name
    return '' if self.hidden?
    source.try(:site_name)
  end

  def has_image?
    return false if self.hidden?
    source.attributes["image"].present? or source.try(:image?)
  end

  def source_url
    source.try(:url)
  end

  def image
    return LinkSource.new.image if self.hidden? or !has_image?
    source.try(:image) or source.try(:attachment)
  end

  def image_height
    return 0 if self.hidden?
    source.try(:image_height) || 0
  end

  def image_width
    return 0 if self.hidden?
    source.try(:image_width) || 0
  end

  def file_source?
    source.is_a? FileSource
  end

  def link_source?
    source.is_a? LinkSource
  end

  def video_source?
    return false unless link_source?
    VideoInfo.usable?(source.try(:url) || '')
  end

  def build_source(params)
    self.source = self.source_type.constantize.new(params) if self.source_type.present?
  end

end
