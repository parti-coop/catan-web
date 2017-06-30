class Survey < ActiveRecord::Base
  include ActionView::Helpers::DateHelper

  include Grape::Entity::DSL
  entity do
    expose :id, :remain_time_human, :feedbacks_count, :feedback_users_count, :expires_at, :multiple_select
    expose :options, using: Option::Entity
    expose :is_open do |instance, options|
      instance.open?
    end
    with_options(if: lambda { |instance, options| options[:current_user].present? }) do
      expose :is_feedbacked_by_me do |instance, options|
        instance.feedbacked?(options[:current_user])
      end
    end
  end

  attr_accessor :duration_days

  has_one :post, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :options, dependent: :destroy
  has_many :messages, as: :messagable, dependent: :destroy
  accepts_nested_attributes_for :options, reject_if: proc { |attributes|
    attributes['body'].try(:strip).blank?
  }

  scope :finite, -> { where.not(expires_at: nil) }
  scope :need_to_reset_sent_closed_message_at, -> {
    finite.where('sent_closed_message_at < expires_at')
  }
  scope :need_to_send_closed_message, -> {
    finite.where('? > expires_at', DateTime.now).where(sent_closed_message_at: nil)
  }

  def feedbacked?(someone)
    feedbacks.exists? user: someone
  end

  def open?
    expires_at.nil? or expires_at.future?
  end

  def setup_expires_at
    if self.duration_days.present?
      case self.duration_days
      when '-1'
        self.touch(:expires_at)
      when '0'
        self.expires_at = nil
      else
       self.assign_expires_after(self.duration_days.to_i.days)
      end
    end
  end

  def assign_expires_after(duration_days)
    self.expires_at = DateTime.now + duration_days
  end

  def visible_feedbacks?(someone)
    feedbacked?(someone) or !open?
  end

  def percentage(option)
    max_feedbacks_count = options.maximum(:feedbacks_count)
    return 0 if max_feedbacks_count == 0 or option.feedbacks_count == 0
    (option.feedbacks_count / max_feedbacks_count.to_f * 100).ceil
  end

  def post_for_message
    post
  end

  def issue_for_message
    post.issue
  end

  def group_for_message
    post.issue.group
  end

  def mvp_options
    @mvp_options if @mvp_options.present?

    mvp_feedbacks_count = options.order(feedbacks_count: :desc).first.try(:feedbacks_count)
    @mvp_options ||= options.where(feedbacks_count: mvp_feedbacks_count)
    @mvp_options = Option.none if @mvp_options.count == options.count
    @mvp_options
  end

  def mvp_option?(option)
    mvp_options.exists?(id: option)
  end

  def feedback_users_count
    feedback_users.count
  end

  def feedback_users
    User.where(id: self.feedbacks.select(:user_id).distinct)
  end

  def remain_time_human
    if self.open?
      return I18n.t('views.survey.remain_time.undefined') if self.expires_at.nil?

      I18n.t('views.survey.remain_time.open', duration: distance_of_time_in_words_to_now(self.expires_at))
    else
      I18n.t('views.survey.remain_time.closed')
    end
  end
end
