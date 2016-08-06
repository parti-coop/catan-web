require 'test_helper'

class ArticlesWithFileSourceTest < ActionDispatch::IntegrationTest
  test '만들어요' do
    sign_in(users(:one))

    post articles_path, article: { issue_id: issues(:issue1).id, body: 'body', source_attributes: { attachment: fixture_file('files/sample.pdf') }, source_type: 'FileSource' }

    assert assigns(:article).persisted?
    assigns(:article).reload

    assert_equal users(:one), assigns(:article).user
    assert_equal 'sample.pdf', assigns(:article).source.name
    assert_equal issues(:issue1).title, assigns(:article).issue.title
    assert_equal 'body', assigns(:article).body

    assert assigns(:article).comments.empty?
  end

  test '고쳐요' do
    sign_in(users(:one))

    put article_path(articles(:article5)), article: { body: 'body', issue_id: issues(:issue2).id, source_attributes: { attachment: fixture_file('files/sample.pdf')}, source_type: 'FileSource' }

    refute assigns(:article).errors.any?
    assigns(:article).reload
    assert_equal 'body', assigns(:article).body
    assert_equal users(:one), assigns(:article).user
    assert_equal issues(:issue2).title, assigns(:article).issue.title
    assert_equal 'sample.pdf', assigns(:article).source.name
  end

  test '세상에 없는 빠띠를 넣으면 저장이 안되요' do
    sign_in(users(:one))

    previous_count = Article.count
    post articles_path, article: { body: 'body', source_attributes: { attachment: fixture_file('files/sample.pdf') }, source_type: 'FileSource', issue_id: -1}
    assert_equal previous_count, Article.count
  end

  test '본문이 없으면 안만들어요' do
    sign_in(users(:one))

    post articles_path, article: { source_attributes: { attachment: fixture_file('files/sample.pdf')}, source_type: 'FileSource', issue_id: issues(:issue1).id }

    refute assigns(:article).persisted?
  end
end
