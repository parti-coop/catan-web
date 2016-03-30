require 'test_helper'

class CommentsTest < ActionDispatch::IntegrationTest
  test '글에 만들어요' do
    sign_in(users(:one))

    post post_comments_path(post_id: articles(:article1).acting_as.id, comment: { body: 'body' })

    assert assigns(:comment).persisted?
    assert_equal 'body', assigns(:comment).body
    assert_equal users(:one), assigns(:comment).user
  end

  test '내용을 수정해요' do
    sign_in(users(:one))

    put comment_path(comments(:comment1), comment: { body: 'body x' })

    refute assigns(:comment).errors.any?
    assert_equal 'body x', assigns(:comment).body
  end

  test '찬성하는 주장에 만들어요' do
    assert opinions(:opinion1).agreed_by? users(:two)

    sign_in(users(:two))

    post post_comments_path(post_id: opinions(:opinion1).acting_as.id, comment: { body: 'body' })

    assert assigns(:comment).persisted?
    assert_equal 'agree', assigns(:comment).choice
  end

  test '투표 안한 주장에 만들어요' do
    refute opinions(:opinion1).voted_by? users(:one)

    sign_in(users(:one))

    post post_comments_path(post_id: opinions(:opinion1).acting_as.id, comment: { body: 'body' })

    assert assigns(:comment).persisted?
    assert_nil assigns(:comment).choice
  end

  test '고쳐요' do
    sign_in(users(:one))

    put comment_path(comments(:comment1), comment: { body: 'body x' })

    assigns(:comment).reload
    assert_equal 'body x', assigns(:comment).body
  end

  test '링크에 달린 수다를 고쳐요' do
    sign_in(users(:one))

    put comment_path(comments(:comment1), comment: { body: 'body x' }, article_link: 'new_url')

    article = assigns(:comment).post.specific.reload
    assert_equal 'new_url', article.link
  end

  test '링크가 같으면 링크가 안 고쳐져요' do
    sign_in(users(:one))

    previsous_post = comments(:comment1).post
    put comment_path(comments(:comment1), comment: { body: 'body x' }, article_link: comments(:comment1).post.specific.link)

    assert_equal previsous_post, comments(:comment1).reload.post
  end

  test '고친 후 원래 링크에 수다가 있으면 남겨져요' do
    sign_in(users(:one))
    previsous_post = comments(:comment1).post

    post post_comments_path(post_id: previsous_post.id, comment: { body: 'body' })
    put comment_path(comments(:comment1), comment: { body: 'body x' }, article_link: 'new_url')

    article = assigns(:comment).post.specific.reload
    assert_equal 'new_url', article.link

    assert Post.exists?(id: previsous_post.id)
  end

  test '고친 후 원래 링크에 수다가 없으면 지워져요' do
    sign_in(users(:one))
    previsous_post = comments(:comment1).post
    assert_equal 1, previsous_post.comments.count

    put comment_path(comments(:comment1), comment: { body: 'body x' }, article_link: 'new_url')

    article = assigns(:comment).post.specific.reload
    assert_equal 'new_url', article.link

    refute Post.exists?(id: previsous_post.id)
  end
end
