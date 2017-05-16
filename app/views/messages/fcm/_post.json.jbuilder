post = message.messagable
issue = post.issue
body = message.action.to_s == 'pinned' ? "#{message.sender.nickname}님이 게시글을 공지했습니다. \"#{post.specific_desc_striped_tags(100)}\"" : "#{post.user.nickname}: #{post.specific_desc_striped_tags(100)}"

json.data do
  json.title "#{issue.title} #{Issue.model_name.human}"
  json.body body
  json.type "post"
  json.priority "high"
  json.param post.id
end
