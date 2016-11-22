class Admin::IssuesController < AdminController
  def merge
    source = Issue.find_by slug: params[:source_slug]
    target = Issue.find_by slug: params[:issue_slug]
    if source.blank? or target.blank?
      flash[:error] = '빠띠를 찾을 수 없습니다'
      redirect_to admin_issues_path and return
    end

    ActiveRecord::Base.transaction do
      MergedIssue.where(issue: source).update_all(issue_id: target.id)
      MergedIssue.create!(source_id: source.id, source_slug: source.slug, issue: target, user: current_user)

      ActiveRecord::Base.record_timestamps = false
      begin
        source.makers.each do |maker|
          user = maker.user
          target.makers.build(user: user, updated_at: maker.updated_at, created_at: maker.created_at) unless target.maker_users.exists?(id: user.id)
        end
        source.members.each do |member|
          user = member.user
          target.members.build(user: user, updated_at: member.updated_at, created_at: member.created_at) unless target.member_users.exists?(id: user.id)
        end
      ensure
        ActiveRecord::Base.record_timestamps = true
      end
      source.blind_users.each do |user|
        target.blinds.build(user: user) unless target.blind_users.exists?(id: user.id)
      end
      source.relateds.each do |related|
        if related.target == target
          next
        end
        if target.relateds.exists?(target: related.target)
          next
        end

        target.relateds.build(target: related.target)
      end
      target.save!

      ActiveRecord::Base.record_timestamps = false
      begin
        source.posts.each do |post|
          origin_updated_at = post.updated_at
          post.specific.update_attributes!(section: target.sections.initial_section,
            updated_at: post.specific.updated_at, issue_id: target.id)
          post.reload.update_attributes!(issue_id: target.id, updated_at: origin_updated_at)
        end
        source.invitations.each do |invitation|
          invitation.update_attributes!(issue: target, updated_at: invitation.updated_at)
        end
        Upvote.where(issue: source).each do |upvote|
          upvote.update_columns(issue_id: target.id, updated_at: upvote.updated_at)
        end
        Issue.reset_counters(target.id, :posts, :members)
      ensure
        ActiveRecord::Base.record_timestamps = true
      end
      source.reload.destroy!
    end

    redirect_to admin_issues_path
  end
end