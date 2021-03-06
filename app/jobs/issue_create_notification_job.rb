class IssueCreateNotificationJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(issue_id, user_id)
    issue = Issue.find_by(id: issue_id)
    return if issue.blank?
    return if issue.private?

    creating_user = User.find_by(id: user_id)
    return if creating_user.blank?

    SendMessage.run(source: issue, sender: creating_user, action: :create_issue)
  end
end
