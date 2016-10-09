module V1
  class Dashboard < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :dashboard do
      desc '내홈의 글을 가져옵니다'
      oauth2
      get :posts do
        watched_posts = resource_owner.watched_posts
        @last_post = watched_posts.newest(field: :last_touched_at)

        previous_last_post = Post.find_by(id: params[:last_id])

        watched_posts = watched_posts.order(last_touched_at: :desc)
        @posts = watched_posts.limit(25).previous_of_post(previous_last_post)

        current_last_post = @posts.last

        @is_last_page = (watched_posts.empty? or watched_posts.previous_of_post(current_last_post).empty?)

        present :isLastPage, @is_last_page
        present :posts, @posts, with: V1::Entities::PostEntity
      end
    end

  end

  module Entities
    class PostEntity < Grape::Entity
      expose :id
      expose :partiTitle do |model|
        model.issue.title
      end
      expose :title do |model|
        model.specific.try(:title)
      end
      expose :body do |model|
        model.specific.try(:body)
      end
    end
  end
end
