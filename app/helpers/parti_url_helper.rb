module PartiUrlHelper
  def issue_home_path(issue, options = {})
    options.update(slug: issue.slug)
    slug_issue_path(options)
  end

  def issue_home_url(issue)
    slug_issue_url(slug: issue.slug)
  end

  def issue_posts_path(issue)
    slug_issue_posts_path(slug: issue.slug)
  end

  def issue_comments_path(issue)
    slug_issue_comments_path(slug: issue.slug)
  end

  def issue_campaign_path(issue)
    slug_issue_campaign_path(slug: issue.slug)
  end

  def user_gallery_path(user)
    nickname_user_path(nickname: user.nickname)
  end

  def user_gallery_url(user)
    nickname_user_url(nickname: user.nickname)
  end

  def user_posts_path(user)
    nickname_user_posts_path(nickname: user.nickname)
  end

  def user_comments_path(user)
    nickname_user_comments_path(nickname: user.nickname)
  end

  def tag_home_path(tag)
    show_tag_path(name: tag.name)
  end

end
