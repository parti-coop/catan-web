class Note < ActiveRecord::Base
  include Postable
  acts_as :post, as: :postable

  validates :body, presence: true

  scope :recent, -> { includes(:post).order('posts.id desc') }
  scope :latest, -> { after(1.day.ago) }
  scope :previous_of_note, ->(note) { joins(:post).where('posts.id < ?', note.acting_as.id) if note.present? }

  def title
    body
  end

  def commenters
    comments.map(&:user).uniq.reject { |u| u == self.user }
  end

  def specific_origin
    self
  end
end
