class PostsController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show, :poll_social_card]
  load_and_authorize_resource

  def index
    posts_page
  end

  def create
    redirect_to root_path and return if fetch_issue.blank?
    @post.reference = @post.reference.unify if @post.reference
    @post.user = current_user
    @post.section = @post.issue.initial_section if @post.section.blank?
    if @post.save
      callback_after_creating_post
    else
      errors_to_flash(@post)
    end
    redirect_to params[:back_url].presence || issue_home_path_or_url(@issue)
  end

  def update
    redirect_to root_path and return if fetch_issue.blank?
    @post.assign_attributes(post_params.delete_if {|key, value| value.empty? })
    @post.reference = @post.reference.try(:unify)
    if @post.save
      callback_after_updating_post
      update_comments
      redirect_to @post
    else
      errors_to_flash @post
      render 'edit'
    end
  end

  def destroy
    @post.destroy
    redirect_to issue_home_path_or_url(@post.issue)
  end

  def show
    if request.headers['X-PJAX']
      render(:partial, layout: false) and return
    else
      @issue = @post.issue
      @last_post = nil
      issus_posts = @issue.posts.order(last_touched_at: :desc)
      @posts = issus_posts.limit(25)
      current_last_post = @posts.last
      @is_last_page = (issus_posts.empty? or issus_posts.previous_of_post(current_last_post).empty?)
    end

    if @post.poll.present?
      prepare_meta_tags title: @post.meta_tag_title,
        description: '어떻게 생각하시나요?',
        image: poll_social_card_post_url(format: :png),
        twitter_card_type: 'summary_large_image'
    else
      prepare_meta_tags title: @post.meta_tag_title
    end
  end

  def poll_social_card
    respond_to do |format|
      format.png do
        if params[:no_cached]
          png = IMGKit.new(render_to_string(layout: nil), width: 1200, height: 630, quality: 10).to_png
          send_data(png, :type => "image/png", :disposition => 'inline')
        else
          if !@post.social_card.file.try(:exists?) or (params[:update] and current_user.try(:admin?))
            file = Tempfile.new(["social_card_#{@post.id.to_s}", '.png'], 'tmp', :encoding => 'ascii-8bit')
            file.write IMGKit.new(render_to_string(layout: nil), width: 1200, height: 630, quality: 10).to_png
            file.flush
            @post.social_card = file
            @post.save
            file.unlink
          end
          if @post.social_card.file.respond_to?(:url)
            data = open @post.social_card.url
            send_data data.read, filename: "social_card.png", :type => "image/png", disposition: 'inline', stream: 'true', buffer_size: '4096'
          else
            send_file(@post.social_card.path, :type => "image/png", :disposition => 'inline')
          end
        end
      end
      format.html { render(layout: nil) }
    end
  end

  def postable_controller?
    true
  end

  private

  def update_comments
    return if params[:comment_body].blank?

    comment = Comment.find_by(id: params[:comment_id])
    return if comment.blank? or comment.user != current_user

    comment.update_attributes(body: params[:comment_body])
  end

  def post_params
    reference_type = params[:post][:reference_type]
    reference_attributes = reference_type.constantize.require_attrbutes if reference_type.present?
    poll = params[:post][:poll_attributes]
    poll_attributes = [:title] if poll.present?
    params.require(:post).permit(:body, :issue_id, :section_id, :reference_type, :has_poll,
      reference_attributes: reference_attributes, poll_attributes: poll_attributes)
  end

  def fetch_issue
    @issue ||= Issue.find_by id: params[:post][:issue_id]
    @post.issue = @issue.presence || @post.issue
  end

  def build_comment
    body = params[:comment_body]
    return if body.blank?
    @post.comments.build(body: body, user: current_user)
  end

  def callback_after_updating_post
    if @post.link_source?
      CrawlingJob.perform_async(@post.reference.id)
    end
  end

  def callback_after_creating_post
    if @post.reference.try(:crawling_status).try(:not_yet?)
      CrawlingJob.perform_async(@post.reference.id)
    end
  end
end