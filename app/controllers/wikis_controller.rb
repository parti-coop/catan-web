class WikisController < ApplicationController
  before_filter :authenticate_user!, except: [:show]
  authorize_resource
  before_action :load_post_and_wiki

  def activate
    render_404 and return if @wiki.blank?
    @wiki.update_attributes(status: 'active')

    errors_to_flash(@post)
    redirect_to wiki_post_path(@post)
  end

  def inactivate
    render_404 and return if @wiki.blank?
    @wiki.update_attributes(status: 'inactive')

    errors_to_flash(@post)
    redirect_to wiki_post_path(@post)
  end

  def purge
    render_404 and return if @wiki.blank?
    @wiki.update_attributes(status: 'purge')

    errors_to_flash(@post)
    redirect_to wiki_post_path(@post)
  end

  def histories
    render_404 and return if @wiki.blank?
    @history_page = @wiki.wiki_histories.recent.page params[:page]
  end

  private

  def load_post_and_wiki
    @post ||= Post.find_by id: params[:id]
    @post = nil if @post.private_blocked?(current_user)
    @wiki ||= @post.try(:wiki)
  end
end
