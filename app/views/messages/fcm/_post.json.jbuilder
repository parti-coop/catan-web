post = message.messagable
issue = post.issue
if message.action.to_s == 'pin_post'
  body = "@#{message.sender.nickname}님이 게시글을 고정했습니다. \"#{post.specific_desc_striped_tags(100)}\""
else
  body = "@#{post.user.nickname}: \"#{post.title}\""
end

json.data do
  json.id message.id
  json.title "#{issue.title} #{Issue.model_name.human}"
  json.body body
  json.type "post"
  json.priority "high"
  json.url fcm_read_message_url(id: message.id, url: smart_post_url(post))
  json.param post.id
end
