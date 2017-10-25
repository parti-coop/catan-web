class User < ActiveRecord::Base
  rolify
  include Grape::Entity::DSL
  entity :id, :nickname, :email do
    include Rails.application.routes.url_helpers
    include PartiUrlHelper

    expose :image_url do |instance|
      instance.image.xs.url
    end
    expose :profile_url do |instance|
      smart_user_gallery_url(instance)
    end
  end

  include UniqueSoftDeletable
  acts_as_unique_paranoid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :confirmable, :omniauthable, :omniauth_providers => [:facebook, :google_oauth2, :twitter]

  # validations
  VALID_NICKNAME_REGEX = /\A[ㄱ-ㅎ가-힣a-z0-9_]+\z/
  AT_NICKNAME_REGEX = /(?:^|[[:space:]])@([ㄱ-ㅎ가-힣a-z0-9_]+)/
  HTML_AT_NICKNAME_REGEX = /(?:^|[[:space:]]|>|&nbsp;)(@[ㄱ-ㅎ가-힣a-z0-9_]+)/

  validates :nickname,
    presence: true,
    exclusion: { in: %w(app new edit index session login logout users admin all crew issue group) },
    format: { with: VALID_NICKNAME_REGEX },
    uniqueness: { case_sensitive: false },
    length: { maximum: 20 }
  validate :nickname_exclude_pattern
  validates :email,
    presence: true,
    format: { with: Devise.email_regexp }

  validates :uid, uniqueness: {scope: [:provider]}
  validates :email, uniqueness: {scope: [:provider]}, if: 'provider == "email"'
  validates :password,
    presence: true,
    confirmation: true,
    length: Devise.password_length,
    if: :password_required?

  validates_confirmation_of :password, if: :password_required?
  validates_length_of       :password, within: Devise.password_length, allow_blank: true

  # filters
  before_save :downcase_nickname
  before_save :set_uid
  before_validation :strip_whitespace, only: :nickname
  after_create :default_member_issues
  after_create :check_invitations, :if => "email.present? && confirmed_at.present?"

  # associations
  has_many :merged_issues, dependent: :nullify
  has_many :messages, dependent: :destroy
  has_many :send_messages, dependent: :destroy, foreign_key: :sender_id, class_name: Message
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :upvotes, dependent: :destroy
  has_many :votings, dependent: :destroy
  has_many :blinds, dependent: :destroy
  has_many :polls, through: :posts
  has_many :issue_organizer_members, -> { where(joinable_type: 'Issue').where(is_organizer: true) }, class_name: Member
  has_many :organizing_issues, through: :issue_organizer_members, source: :joinable, source_type: Issue
  has_many :group_organizer_members, -> { where(joinable_type: 'Group').where(is_organizer: true)}, class_name: Member
  has_many :organizing_groups, through: :group_organizer_members, source: :joinable, source_type: Group
  has_many :mentions, dependent: :destroy
  has_many :members, dependent: :destroy
  has_many :member_request, dependent: :destroy
  has_many :member_issues, through: :members, source: :joinable, source_type: Issue
  has_many :member_groups, through: :members, source: :joinable, source_type: Group
  has_many :device_tokens, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :received_invitations, dependent: :destroy, foreign_key: :recipient_id, class_name: Invitation
  has_many :feedbacks, dependent: :destroy
  has_many :options, dependent: :destroy
  has_many :group, dependent: :nullify
  has_many :destroyed_issues, dependent: :nullify, foreign_key: :destroyer_id, class_name: Issue
  has_many :summary_emails, dependent: :destroy
  has_many :last_touched_wiki, dependent: :nullify, class_name: Wiki, foreign_key: :last_author_id
  has_many :wiki_histories, dependent: :nullify
  has_many :decision_histories, dependent: :nullify

  ## uploaders
  # mount
  mount_uploader :image, UserImageUploader

  # scopes
  scope :latest, -> { after(1.day.ago) }
  scope :recent, -> { order(created_at: :desc) }
  scope :previous_of_recent, ->(user) {
    base = recent
    base = base.where('users.created_at < ?', user.created_at) if user.present?
    base
  }

  def admin?
    has_role?(:admin)
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def self.parse_omniauth(data)
    {provider: data['provider'], uid: data['uid'], email: data['info']['email'], image: data['info']['image']}
  end

  def self.find_for_omniauth(auth)
    where(provider: auth[:provider], uid: auth[:uid]).first
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    email = conditions.delete(:email)
    where(conditions.to_h).where(["provider = 'email' AND uid = :value", { :value => email.downcase }]).first
  end

  def self.new_with_session(params, session)
    resource = super
    auth = session["devise.omniauth_data"]
    if auth.present?
      auth["email"] = params['email'] if params['email'].present?
      resource.assign_attributes(auth)
      resource.password = Devise.friendly_token[0,20]
      resource.confirmed_at = DateTime.now
      resource.remote_image_url = auth['image']
    else
      resource.provider = 'email'
    end
    resource
  end

  def self.create_by_external_auth!(external_auth, nickname, email)
    User.create! uid: external_auth.uid,
      provider: external_auth.provider,
      email: (external_auth.email || email),
      password: Devise.friendly_token[0,20],
      confirmed_at: DateTime.now,
      enable_mailing_summary: true,
      enable_mailing_pin: true,
      enable_mailing_mention: true,
      enable_mailing_poll_or_survey: true,
      nickname: nickname,
      remote_image_url: external_auth.image_url
  end

  def writing_counts
    counts = OpenStruct.new
    counts.parties_count = member_issues.count
    counts.posts_count = posts.count
    counts.comments_count = comments.count
    counts.latest_posts_count = posts.latest.count
    counts
  end

  def need_to_more_member?(group = nil)
    member_issues.displayable_in_current_group(group).empty?
  end

  def hottest_posts(count)
    posts.hottest.limit(count)
  end

  def is_organizer?(joinable)
    joinable.organized_by?(self)
  end

  def only_all_member_issues
    member_issues.where.not(id: issue_organizer_members.select(:joinable_id))
  end

  def watched_posts(group = nil)
    Post.where(issue: member_issues.displayable_in_current_group(group))
  end

  def watched_comments(group = nil)
    Comment.where(post: watched_posts(group))
  end

  def mentionable? someone
    return false if someone.blank?
    return false if someone == self
    return true
  end

  def slug
    nickname.try(:ascii_only?) ? nickname : "~#{id}"
  end

  def self.slug_to_id(slug)
    return nil unless slug[0] == '~'
    Integer(slug[1..-1]) rescue nil
  end

  def sent_new_posts_email_today!
    update_attributes(sent_new_posts_email_at: Date.today)
  end

  def sent_new_posts_email_today?
    sent_new_posts_email_at.present? and sent_new_posts_email_at >= Date.today
  end

  def after_confirmation
    check_invitations
  end

  def current_device_tokens
    application_id = { 'production' => 'xyz.parti.catan', 'development' => 'xyz.parti.catan.debug' }[Rails.env]
    return [] if application_id.blank?

    device_tokens.where(application_id: application_id)
  end

  def update_last_read_message(messages)
    max_message_id = messages.reorder('id desc').first.try(:id)
    return if max_message_id.blank?
    update_columns(last_read_message_id: max_message_id) if last_read_message_id.blank? or last_read_message_id <= max_message_id
  end

  def unread_messages_count
    messages.where('id > ?', last_read_message_id).count
  end

  # summary emails
  def self.need_to_delivery(code)
    joins("LEFT OUTER JOIN summary_emails se ON users.id = se.user_id")
    .where("se.id is null or se.mailed_at <= ?", SummaryEmail.limit_datetime(code))
    .order("se.mailed_at")
  end

  def need_to_delivery?(code)
    !summary_emails.where("mailed_at > ?", SummaryEmail.limit_datetime(code)).exists?(code)
  end

  def mail_delivered!(code)
    m = summary_emails.find_or_initialize_by(code: code)
    m.mailed_at = DateTime.now
    m.save!
  end

  private

  def downcase_nickname
    self.nickname = nickname.downcase
  end

  def set_uid
    self.uid = self.email if self.provider == 'email'
  end

  def default_member_issues
    issue = Issue.of_slug Issue::SLUG_OF_PARTI_PARTI
    Member.create(user: self, joinable: issue) if issue.present?
  end

  def check_invitations
    ActiveRecord::Base.transaction do
      invitations = Invitation.where(recipient_email: self.email)
      invitations.each do |invitation|
        member = MemberGroupService.new(group: invitation.joinable, user: self).call
        if member.persisted?
          MessageService.new(member, sender: invitation.user, action: :admit).call
        end
      end
      invitations.destroy_all
    end
  end

  def nickname_exclude_pattern
    if (self.nickname =~ /\Aparti.*\z/i) and (self.nickname_was !~ /\Aparti.*\z/i)
      errors.add(:nickname, I18n.t('errors.messages.taken'))
    end
  end

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def strip_whitespace
    self.nickname = self.nickname.strip unless self.nickname.nil?
  end
end
