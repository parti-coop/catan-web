class PostCreateService
  def initialize(post:, current_user:)
    @post = post
    @current_user = current_user
  end

  def call
    return false if @post.issue.blank?
    return false unless @post.issue.postable?(@current_user)

    @post.user = @current_user
    if @post.wiki.present?
      @post.wiki.last_author = @current_user
      @post.wiki.format_body
    end
    if @post.event.present?
      @post.event.roll_calls.build(user: @current_user, status: :attend)
    end
    @post.strok_by(@current_user)
    @post.format_body

    @post.setup_link_source
    set_current_user_to_options(@post, @current_user)

    @post.pinned = (@post.pinned? and Ability.new(@current_user, @post.issue.group).can?(:pin, @post))
    if @post.pinned?
      @post.pinned_at = DateTime.now
      @post.pinned_by = @current_user
    end

    return false unless @post.save

    @post.read!(@current_user)
    StrokedPostUserJob.perform_async(@post.id)
    @post.issue.strok_by!(@current_user, @post)
    @post.issue.deprecated_read_if_no_unread_posts!(@current_user)
    crawling_after_creating_post
    @post.perform_messages_with_mentions_async(:create)
    if @post.pinned?
      PinJob.perform_async(@post.id, @current_user.id)
    end

    return true
  end

  private

  def set_current_user_to_options(post, current_user)
    (post.survey.try(:options) || []).each do |option|
      option.user = current_user
    end
  end

  def crawling_after_creating_post
    if @post.link_source.try(:crawling_status).try(:not_yet?)
      CrawlingJob.perform_async(@post.link_source.id)
    end
  end
end
