require 'test_helper'

class IssuesTest < ActionDispatch::IntegrationTest
  test '로그인 안해도 첫페이지가 잘보여요' do
    get root_path
    assert_response :success
  end

  test '만들어요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })

    assert assigns(:issue).persisted?
    assert_equal 'title', assigns(:issue).title

    assert_equal users(:one), assigns(:issue).last_stroked_user
  end

  test '카테고리 안에 만들어요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body', category_slug: Category::GWANGJU_AGENDA.slug, group_slug: 'gwangju' })
    assert assigns(:issue).persisted?
    assert_equal Category::GWANGJU_AGENDA.slug, assigns(:issue).category_slug
  end

  test '만든 사람이 오거나이저가 되어요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })

    assert assigns(:issue).reload.organized_by?(users(:one))
  end

  test '만든 사람은 멤버가 되어요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })

    assert assigns(:issue).reload.member?(users(:one))
  end

  test '같은 주소로는 못 만들어요' do
    sign_in(users(:one))

    post issues_path, issue: { title: 'title', slug: 'title', body: 'body' }
    assert assigns(:issue).persisted?

    post issues_path, issue: { title: 'title', slug: 'title', body: 'body' }
    refute assigns(:issue).persisted?

    host! "gwangju.example.com"

    post issues_path, issue: { title: 'title', slug: 'title', body: 'body' }
    assert assigns(:issue).persisted?

    post issues_path, issue: { title: 'title', slug: 'title', body: 'body' }
    refute assigns(:issue).persisted?
  end

  test 'union그룹에만 parti빠띠를 만들어요' do
    sign_in(users(:one))

    host! "www.example.com"
    post issues_path, issue: { title: 'title', slug: Issue::SLUG_OF_PARTI_PARTI, body: 'body', group_slug: 'xx' }
    refute assigns(:issue).persisted?
  end

  test '대소문자를 안가려요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'Title', slug: 'Title', body: 'body' })
    assert assigns(:issue).persisted?
    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })
    refute assigns(:issue).persisted?
  end

  test '고쳐요' do
    sign_in(users(:organizer))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x' })

    assigns(:issue).reload
    assert_equal 'title x', assigns(:issue).title
  end

  test '오거나이저를 넣어요' do
    sign_in(users(:organizer))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x', organizer_nicknames: users(:one).nickname })

    assigns(:issue).reload
    assert assigns(:issue).organizer_members.exists?(user: users(:one))
  end

  test '중복된 오거나이저를 넣으면 알아서 넣어줘요.' do
    sign_in(users(:organizer))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x', organizer_nicknames: "#{users(:organizer).nickname},#{users(:one).nickname},#{users(:one).nickname}" })

    assigns(:issue).reload
    assert assigns(:issue).organizer_members.exists?(user: users(:one))
  end

  test '오거나이저를 삭제하면 빼줘요' do
    sign_in(users(:organizer))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x', organizer_nicknames: "#{users(:organizer).nickname}, #{users(:one).nickname}, #{users(:three).nickname}" })
    assigns(:issue).reload
    assert assigns(:issue).organizer_members.exists?(user: users(:one))
    assert assigns(:issue).organizer_members.exists?(user: users(:three))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x', organizer_nicknames: "#{users(:organizer).nickname}, #{users(:one).nickname}" })
    assigns(:issue).reload
    assert assigns(:issue).organizer_members.exists?(user: users(:one))
    refute assigns(:issue).organizer_members.exists?(user: users(:three))
  end

  test '블라인드할 사용자를 넣어요' do
    sign_in(users(:organizer))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x', blinds_nickname: users(:one).nickname })

    assigns(:issue).reload
    assert_equal users(:one), assigns(:issue).blinds.first.user
  end

  test '중복된 블라인드를 넣으면 알아서 넣어줘요.' do
    sign_in(users(:organizer))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x', blinds_nickname: "#{users(:one).nickname},#{users(:one).nickname}" })

    assigns(:issue).reload
    assert_equal users(:one), assigns(:issue).blinds.first.user
  end

  test 'all이라는 이슈는 못만들어요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'all', slug: 'all', body: 'body' })

    refute assigns(:issue).persisted?
  end

  test '오거나이저넣기' do
    sign_in(users(:organizer))
    put issue_path(issues(:issue1), issue: { organizer_nicknames: 'nick1' })

    assert assigns(:issue).organizer_members.exists?(user: users(:one))
  end

  test '그룹빠띠' do
    host! "gwangju.example.com"
    sign_in(users(:one))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })

    assert assigns(:issue).persisted?
    assert_equal 'gwangju', assigns(:issue).group.slug
  end
end
