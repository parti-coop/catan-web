class VotingsController < ApplicationController
  before_action :authenticate_user!, only: :create

  def create
    @poll = Poll.find_by id: params[:poll_id]
    if @poll.blank?
      render_404 and return
    end
    if @poll.post.blank? or @poll.post.private_blocked?(current_user)
      render_404 and return
    end

    service = VotingPollService.new(poll: @poll, current_user: current_user)
    @voting = service.send(params[:voting][:choice].to_sym)
    @poll.post.read!(current_user)
    @poll.reload
    respond_to do |format|
      format.js
      format.html {
        if helpers.explict_front_namespace?
          flash.now[:notice] = @poll.sured_by?(current_user) ? '투표했습니다' : '투표를 취소했습니다'
          render(partial: '/front/posts/show/poll', locals: { poll: @poll })
        else
          redirect_to_origin
        end
      }
    end
  end

  def users
    @poll = Poll.find_by id: params[:poll_id]
    if @poll.blank?
      render_404 and return
    end

    if helpers.explict_front_namespace?
      render(partial: 'front/posts/show/poll/votings/users', locals: { poll: @poll })
    else
      render layout: nil
    end
  end

  private

  def redirect_to_origin
    redirect_to @voting.poll
  end
end
