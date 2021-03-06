class IssueDestroyJob < ApplicationJob
  include Sidekiq::Worker

  def perform(organizer_id, issue_id, message)
    organizer = User.find_by(id: organizer_id)
    issue = Issue.find_by(id: issue_id)
    return if organizer.blank? or issue.blank?

    mailing_user_ids = (issue.posts.pluck(:user_id) + issue.members.pluck(:user_id) + issue.member_requests.pluck(:user_id)).uniq

    ActiveRecord::Base.transaction do
      issue.update_attributes(destroyer: organizer)
      issue.posts.each do |post|
        PostDestroyService.new(post).call
      end
      Message.where(messagable: issue.members_with_deleted).destroy_all
      Message.where(messagable: issue.member_requests_with_deleted).destroy_all

      User.where(id: issue.members.select(:user_id)).update_all(member_issues_changed_at: Time.current)
      issue.destroy!
    end
  end
end
