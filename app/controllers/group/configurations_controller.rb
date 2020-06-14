class Group::ConfigurationsController < Group::BaseController
  skip_before_action :verify_current_group, only: [:new, :create]
  before_action :authenticate_user!
  before_action :only_organizer, only: [:edit, :update, :front_wiki, :destroy_front_wiki]

  def new
    @group = Group.new
    @group.user = current_user
    @group.members.build(user: current_user, is_organizer: true)
    render layout: 'application'
  end

  def create
    @group = Group.new(group_params)
    @group.plan = Group.plan.lite
    @group.user = current_user
    @group.slug = params[:group][:slug]
    if @group.title.present?
      @group.logo = "data:image/png;base64,#{Catan::Avatar::generate_avatar(@group.title)}"
    end
    @group.members.build(user: current_user, is_organizer: true)

    if @group.save
      general_issue = Issue.create(title: '일반 채널', slug: 'general', group_slug: @group.slug)
      IssueCreateService.new(issue: general_issue, current_user: current_user, current_group: @group, flash: flash).call
      random_issue = Issue.create(title: '잡담', slug: 'random', group_slug: @group.slug)
      IssueCreateService.new(issue: random_issue, current_user: current_user, current_group: @group, flash: flash).call
      redirect_to smart_group_url(@group)
    else
      render 'new', layout: 'application'
    end
  end

  def edit
    @group = current_group
  end

  def update
    @group = current_group
    @group.assign_attributes(group_params)

    new_organizer_members = []
    ActiveRecord::Base.transaction do
      if params[:group].has_key?(:organizer_nicknames)
        organizer_users = User.parse_nicknames(@group.organizer_nicknames)
        organizer_users.each do |user|
          member = @group.members.find_by(user: user)
          if member.blank?
            if @group.comprehensive_joined_by?(user)
              member = MemberGroupService.new(group: @group, user: user).call
            else
              next
            end
          end

          unless member.is_organizer?
            member.update_attributes(is_organizer: true)
            new_organizer_members << member
          end
        end
        @group.organizer_members.each do |member|
          member.update_attributes(is_organizer: false) unless organizer_users.include? member.user
        end
      end

      if @group.save
        #그룹 변경 노티 필요
        #MessageService.new(@group, sender: current_user).call
        old_organizer_members = @group.organizer_members.to_a - new_organizer_members
        new_organizer_members.each do |member|
          next if member.user == current_user
          MessageService.new(member, sender: current_user, action: :new_organizer).call(old_organizer_members: old_organizer_members)
          MemberMailer.on_new_organizer(member.id, current_user.id).deliver_later
        end

        if helpers.explict_front_namespace?
          flash[:notice] = t('activerecord.successful.messages.created')
          turbolinks_redirect_to root_url(subdomain: @group.subdomain)
        else
          flash[:success] = t('activerecord.successful.messages.created')
          redirect_to smart_group_url(@group)
        end
      else
        errors_to_flash @group
        if helpers.explict_front_namespace?
          render_front_edit(@group)
        else
          render 'edit'
        end
      end
    end
  end

  def remove_key_visual_foreground_image
    @group = current_group
    @group.remove_key_visual_foreground_image!
    @group.save
    flash[:success] = t('activerecord.successful.messages.deleted')
    redirect_to edit_group_configuration_path
  end

  def remove_key_visual_background_image
    @group = current_group
    @group.remove_key_visual_background_image!
    @group.save
    flash[:success] = t('activerecord.successful.messages.deleted')
    redirect_to edit_group_configuration_path
  end

  def front_wiki
    @post = Post.find(params[:post_id])
    @group = @post.issue.group

    @group.front_wiki_post = @post
    @group.front_wiki_post_by = current_user
    @group.save!
  end

  def destroy_front_wiki
    @post = Post.find(params[:post_id])
    @group = @post.issue.group

    @group.front_wiki_post = nil
    @group.front_wiki_post_by = current_user
    @group.save!
  end

  private

  def group_params
    # 민감한 정보인 slug은 따로 받습니다
    params.require(:group).permit(:title, :site_description, :site_title,
      :head_title, :site_keywords, :issue_creation_privileges, :private, :organizer_nicknames,
      :key_visual_foreground_image, :key_visual_foreground_image_cache,
      :key_visual_background_image, :key_visual_background_image_cache, :frontable)
  end

  def render_front_edit group
    force_remote_replace_header
    render partial: 'front/groups/form', locals: {
      local_group: group,
    }
  end
end
