require 'test_helper'

class CommentsTest < ActionDispatch::IntegrationTest
  test '글에 만들어요' do
    sign_in(users(:one))

    post post_comments_path(post_id: articles(:article1).acting_as.id, comment: { body: 'body' }), format: :js

    assert assigns(:comment).persisted?
    assert_equal 'body', assigns(:comment).body
    assert_equal users(:one), assigns(:comment).user
  end

  test '내용을 수정해요' do
    sign_in(users(:one))

    put comment_path(comments(:comment1), comment: { body: 'body x' }), format: :js

    refute assigns(:comment).errors.any?
    assert_equal 'body x', assigns(:comment).body
  end

  test '댓글을 달면 메시지가 보내져요' do
    comment = comments(:comment1)
    assert comment.post.comments.users.include?(users(:one))

    sign_in(users(:two))
    post post_comments_path(post_id: comment.post.id, comment: { body: 'body' }), format: :js

    refute assigns(:comment).errors.any?
    assert_equal assigns(:comment), users(:one).messages.first.messagable
  end

  test '찬성하는 주장에 만들어요' do
    assert opinions(:opinion1).agreed_by? users(:two)

    sign_in(users(:two))

    post post_comments_path(post_id: opinions(:opinion1).acting_as.id, comment: { body: 'body' }), format: :js

    assert assigns(:comment).persisted?
    assert_equal 'agree', assigns(:comment).choice
  end

  test '업보트한 경우 댓글을 달면 메시지가 보내져요' do
    assert opinions(:opinion1).agreed_by? users(:two)

    sign_in(users(:one))
    post post_comments_path(post_id: opinions(:opinion1).acting_as.id, comment: { body: 'body' }), format: :js

    refute assigns(:comment).errors.any?
    assert_equal assigns(:comment), users(:two).messages.first.messagable
  end

  test '투표 안한 주장에 만들어요' do
    refute opinions(:opinion1).voted_by? users(:one)

    sign_in(users(:one))

    post post_comments_path(post_id: opinions(:opinion1).acting_as.id, comment: { body: 'body' }), format: :js

    assert assigns(:comment).persisted?
    assert_nil assigns(:comment).choice
  end

  test '고쳐요' do
    sign_in(users(:one))

    put comment_path(comments(:comment1), comment: { body: 'body x' }), format: :js

    assigns(:comment).reload
    assert_equal 'body x', assigns(:comment).body
  end
end
