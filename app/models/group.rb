class Group < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :title, :slug

  include UniqueSoftDeletable
  acts_as_unique_paranoid

  include Invitable

  mount_uploader :logo, ImageUploader
  mount_uploader :cover, ImageUploader

  SLUG_OF_UNION = 'union'

  belongs_to :user
  has_many :invitations, as: :joinable, dependent: :destroy
  has_many :members, as: :joinable, dependent: :destroy
  has_many :organizer_members, -> { where(is_organizer: true) }, as: :joinable, class_name: Member
  has_many :member_users, through: :members, source: :user
  has_many :member_requests, as: :joinable, dependent: :destroy
  has_many :member_request_users, through: :member_requests, source: :user
  has_many :issues, dependent: :restrict_with_error, primary_key: :slug, foreign_key: :group_slug

  default_scope -> { order("case when slug = 'indie' then 0 else 1 end").order("if(ascii(substring(title, 1)) < 128, 1, 0)").order(:title) }
  scope :but, ->(group) { where.not(id: group) }
  scope :not_private_blocked, ->(current_user) { where.any_of(
                                                    where(id: Member.where(user: current_user).where(joinable_type: 'Group').select('members.joinable_id')),
                                                    where.not(private: true)) }

  def find_category_by_slug(slug)
    categories.detect { |c| c.slug == slug }
  end

  def title_share_format
    indie? ? nil : "#{title} 빠띠"
  end

  def title_basic_format
    indie? ? "빠띠" : "#{title} 그룹"
  end

  def title_short_format
    indie? ? "빠띠" : title
  end

  def categorized_issues(category = nil)
    issues.categorized_with(category.try(:slug))
  end

  def categories
    if slug == 'gwangju'
      [
        Category::GWANGJU_AGENDA,
        Category::GWANGJU_COMMUNITY,
        Category::GWANGJU_PROJECT,
        Category::GWANGJU_STATESMAN,
      ]
    elsif slug == 'meetshare'
      [
        Category::MEETSHARE_WORK,
        Category::MEETSHARE_GENDER,
        Category::MEETSHARE_CULTURE,
        Category::MEETSHARE_GREEN,
        Category::MEETSHARE_LIFE,
        Category::MEETSHARE_ACTIVIST
      ]
    else
      []
    end
  end

  def private_blocked?(someone = nil)
    !member?(someone) && private?
  end

  def organized_by? someone
    organizer_members.exists? user: someone
  end

  def member? someone
    members.exists? user: someone
  end

  def member_of someone
    members.find_by(user: someone)
  end

  def form_select_title
    if indie?
      I18n.t('views.indie_form_select_title')
    else
      head_title
    end
  end

  def title
    read_attribute(:title) || read_attribute(:name)
  end

  def member_requested?(someone)
    member_requests.exists? user: someone
  end

  def seo_image
    if File.exist?("app/assets/images/groups/#{self.slug}_seo.png")
      "groups/#{self.slug}_seo.png"
    else
      "parti_seo.png"
    end
  end

  def subdomain
    indie? ? nil : self.slug
  end

  def indie?
    self.slug == 'indie'
  end

  def out_of_member_users member_users
    member_users.to_a.select { |user| !member?(user) }
  end

  def comprehensive_joined_by?(someone)
    Group.comprehensive_joined_by(someone).exists?(id: self)
  end

  def default_issues
    issues.where(is_default: true)
  end

  def is_light_theme?
    %(indie).include?(self.slug)
  end

  def self.comprehensive_joined_by(someone)
    self.where(slug: (someone.member_issues.select(:group_slug)))
        .or(self.where(id: someone.member_groups))
  end

  def self.find_by_slug(slug)
    find_by(slug: slug)
  end

  def self.exists_slug?(slug)
    exists? slug: slug
  end

  def self.default_slug(current_group)
    current_group.try(:slug) || (current_group if current_group.is_a?(String)) || 'indie'
  end

  def self.indie
    find_by(slug: 'indie')
  end

  def pinned_posts(someone)
    noticed_issues = self.issues.only_public_in_current_group.to_a
    if someone.present?
      noticed_issues += self.issues.where(id: someone.member_issues).to_a
      noticed_issues.uniq!
    end

    pinned_posts = noticed_issues.map do |issue|
      issue.posts.pinned.to_a
    end.flatten.compact
    pinned_posts.sort_by { |post| post.created_at }.reverse
  end

  def guide_link
    if 'zakdang' == slug
      "https://wouldyouparty.gitbooks.io/party_guide/"
    elsif %w(slowalk westay1 Group::SLUG_OF_UNION adaptiveleadership youthpolicynet).include? slug
      "https://parti-xyz.gitbooks.io/org-guide/content/"
    else
      "https://parti-xyz.gitbooks.io/issue-guide/content/"
    end
  end

  def members_with_deleted
    Member.with_deleted.where(joinable: self)
  end

  def member_requests_with_deleted
    MemberRequest.with_deleted.where(joinable: self)
  end
end
