class IssueForceDefaultJob
  include Sidekiq::Worker

  def perform(issue_id, organizer_user_id)
    issue = Issue.find_by(id: issue_id)
    return if issue.blank? or issue.indie_group?

    organizer_user = User.find_by(id: organizer_user_id)
    return if organizer_user.blank?

    issue.group.members.each do |group_member|
      new_member = MemberIssueService.new(issue: issue, user: group_member.user, need_to_message_organizer: false).call
      if new_member.try(:persisted?)
        MessageService.new(new_member, sender: organizer_user, action: :force_default).call
        MemberMailer.deliver_all_later_on_force_default(new_member, organizer_user)
      end
    end
  end
end
