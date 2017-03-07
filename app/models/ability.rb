class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :poll_social_card, :partial, :modal], :all
    can [:slug, :users, :exist, :new_posts_count, :slug_home,
      :slug_users, :slug_references, :slug_comments, :slug_polls,
      :slug_posts, :slug_wikis, :search], Issue
    if user
      can [:update, :destroy, :remove_logo, :remove_cover], Issue do |issue|
        user.is_organizer?(issue)
      end
      can [:create, :new_intro, :search_by_tags], [Issue]

      can [:update, :destroy], [Post], user_id: user.id
      can :create, [Post] do |post|
        post.issue.try(:postable?, user)
      end
      can [:pin, :unpin], Post do |post|
        user.is_organizer?(post.issue)
      end

      can :manage, [Comment, Vote, Upvote, Member], user_id: user.id
      can [:create], MemberRequest, user_id: user.id
      can [:accept, :reject], MemberRequest do |request|
        user.is_organizer?(request.issue)
      end
      can :manage, Related do |related|
        user.is_organizer?(related.issue)
      end
      can :update, Wiki
      can :destroy, Option do |option|
        option.user == user and option.feedbacks_count == 0
      end
      if user.admin?
        can :manage, [Issue, Related, Blind, Role, Group]
      end
    end
  end
end
