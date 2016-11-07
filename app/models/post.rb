class Post < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    expose :id, :upvotes_count
    expose :user, using: User::Entity
    expose :issue, using: Issue::Entity, as: :parti
    expose :parsed_title do |instance|
      instance.specific.try(:parsed_title)
    end
    expose :parsed_body do |instance|
      instance.specific.try(:parsed_body)
    end
    expose :created_at, format_with: lambda { |dt| dt.iso8601 }

    with_options(if: lambda { |instance, options| !!options[:current_user] }) do
      expose :is_upvotable do |instance, options|
        instance.upvotable? options[:current_user]
      end
      expose :is_blinded do |instance, options|
        instance.blinded? options[:current_user]
      end
    end

    with_options(if: lambda { |instance, options| options[:type] == :full }) do
      expose :link_reference, using: LinkSource::Entity, if: lambda { |instance, options| instance.specific.link_source? } do |instance|
        instance.specific.reference
      end
      expose :file_reference, using: FileSource::Entity, if: lambda { |instance, options| instance.specific.file_source? } do |instance|
        instance.specific.reference
      end
      expose :poll, using: Poll::Entity, if: lambda { |instance, options| instance.specific.poll.present? } do |instance|
        instance.specific.poll
      end
      expose :comments, using: Comment::Entity do |instance|
        instance.comments.sequential
      end
    end
  end

  HOT_LIKES_COUNT = 3

  include Upvotable

  acts_as_paranoid
  actable as: :postable
  paginates_per 20

  belongs_to :issue, counter_cache: true
  belongs_to :user
  has_many :comments, dependent: :destroy do
    def users
      self.map(&:user).uniq
    end
  end
  has_many :votes, dependent: :destroy do
    def users
      self.map(&:user).uniq
    end

    def partial_included_with(someone)
      partial = recent.limit(100)
      if !partial.map(&:user).include?(someone)
        (partial.all << find_by(user: someone)).compact
      else
        partial.all
      end
    end

    def point
      agreed.count - disagreed.count
    end
  end

  # validations
  validates :issue, presence: true
  validates :user, presence: true

  # scopes
  default_scope -> { joins(:issue) }
  scope :recent, -> { order(created_at: :desc) }
  scope :hottest, -> { order(recommend_score_datestamp: :desc, recommend_score: :desc) }
  scope :previous_of_hottest, ->(post) {
    base = hottest.order(id: :desc)
    base = base.where('posts.recommend_score > 0')
    base = base.where.not(recommend_score_datestamp: nil)
    base = base.where.any_of(
      ['posts.recommend_score < ?', post.recommend_score],
      where('posts.recommend_score = ? and posts.recommend_score_datestamp < ?',
        post.recommend_score, post.recommend_score_datestamp),
      where('posts.recommend_score = ? and posts.recommend_score_datestamp = ? and posts.id < ?',
        post.recommend_score, post.recommend_score_datestamp, post.id)
    ) if post.present?
    base
  }

  scope :watched_by, ->(someone) { where(issue_id: someone.watched_issues) }
  scope :by_postable_type, ->(t) { where(postable_type: t.camelize) }
  scope :only_talks, -> { by_postable_type(Talk.to_s) }
  scope :only_notes, -> { by_postable_type(Note.to_s) }
  scope :latest, -> { after(1.day.ago) }
  scope :previous_of_post, ->(post) { where('posts.last_touched_at < ?', post.last_touched_at) if post.present? }
  scope :next_of_post, ->(post) { where('posts.last_touched_at > ?', post.last_touched_at) if post.present? }
  scope :only_group_or_all_if_blank, ->(group) { joins(:issue).where('issues.group_slug' => group.slug) if group.present? }

  ## uploaders
  # mount
  mount_uploader :social_card, ImageUploader

  # callbacks
  before_create :touch_last_touched_at
  after_create :touch_last_touched_at_of_issues

  def vote_by voter
    votes.where(user: voter).first
  end

  def voted_by? voter
    votes.exists? user: voter
  end

  def specific_desc
    specific.try(:title) || specific.try(:parsed_title) || specific.try(:body)
  end

  def specific_desc_striped_tags
    ActionView::Base.full_sanitizer.sanitize(specific_desc)
  end

  def origin
    specific.specific_origin.post
  end

  def messagable_users
    (comments.users + (specific.poll.try(:votings).try(:users) || [])).uniq
  end

  def latest_comments
    comments.recent.limit(2).reverse
  end

  def blinded? someone
    return false if someone == self.user
    issue.blind_user? self.user
  end

  def upvotable? someone
    return false if someone.blank?
    !upvotes.exists?(user: someone)
  end

  def self.recommends(exclude)
    result = recent.limit(10)
    if result.length < 10
      result += recent.limit(10)
      result = result.uniq
    end
    result - [exclude]
  end

  def self.hottest_count
    hottest.length
  end

  def self.best_talks_in_issues(issues, count)
    self.where(issue: issues).only_talks.hottest.limit(count)
  end

  private

  def touch_last_touched_at
    self.last_touched_at = DateTime.now
  end

  def touch_last_touched_at_of_issues
    self.issue.touch(:last_touched_at)
  end
end
