require 'test_helper'

class MergeIssuesTest < ActionDispatch::IntegrationTest
  test '합쳐요' do
    maker_users = [:target_maker, :source_maker, :bat_maker1].map { |slug| makers(slug).user }
    member_users = [:target_member, :source_member, :bat_member1].map { |slug| members(slug).user }
    blind_users = [:target_blind, :source_blind, :bat_blind1].map { |slug| blinds(slug).user }
    old_post_updated_at = posts(:source_post).updated_at
    old_invitation_updated_at = invitations(:source_invitation).updated_at
    old_upvote_updated_at = upvotes(:upvote3).updated_at

    sign_in(users(:admin))
    post merge_admin_issues_path, issue_slug: issues(:merge_target_issue).slug, source_slug: issues(:merge_source_issue).slug
    issues(:merge_target_issue).reload

    # source이슈가 사라집니다
    refute Issue.exists?(id: issues(:merge_source_issue).id)

    # 메이커가 합쳐집니다
    maker_users.each do |user|
      assert issues(:merge_target_issue).made_by?(user)
    end

    # 멤버가 합쳐집니다
    member_users.each do |user|
      assert issues(:merge_target_issue).member?(user)
    end

    # post가 합쳐집니다
    assert_equal issues(:merge_target_issue), posts(:source_post).reload.issue
    assert_equal old_post_updated_at, posts(:source_post).updated_at
    assert_equal issues(:merge_target_issue).sections.initial_section, posts(:source_post).specific.section

    # blind유저가 합쳐집니다
    blind_users.each do |user|
      assert issues(:merge_target_issue).blind_user?(user)
    end

    # 초대가 합쳐집니다
    assert_equal issues(:merge_target_issue), invitations(:source_invitation).reload.issue
    assert_equal old_invitation_updated_at, invitations(:source_invitation).updated_at

    # 연관빠띠가 합쳐집니다
    expected_related_issues = [:issue4, :issue2].map { |slug| issues(slug) }
    assert_equal expected_related_issues.length, issues(:merge_target_issue).relateds.count
    expected_related_issues.each do |issue|
      assert issues(:merge_target_issue).related_with?(issue)
    end

    # talk가 합쳐집니다
    assert_equal issues(:merge_target_issue), talks(:talk7).reload.post_issue

    # upvotes가 합쳐집니다
    assert_equal issues(:merge_target_issue), upvotes(:upvote3).reload.issue
    assert_equal old_upvote_updated_at, upvotes(:upvote3).updated_at

  end
end
