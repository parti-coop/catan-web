include GroupHelper
include MobileAppHelper

Rails.application.routes.draw do
  class IndieGroupRouteConstraint
    def matches?(request)
      fetch_group(request).blank?
    end
  end

  use_doorkeeper
  mount API, at: '/'

  post '/tinymce_assets' => 'tinymce_assets#create'

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    omniauth_callbacks: 'users/omniauth_callbacks',
    passwords: 'users/passwords',
    sessions: 'users/sessions'
  }
  get 'after_sign_out', to: redirect { |path_params, request|
    if is_mobile_app_get_request?(request)
      Rails.application.routes.url_helpers.mobile_app_teardown_sessions_path(after_sign_out_path: request.params[:after_sign_out_path])
    else
      request.params[:after_sign_out_path]
    end
  }

  ## 그룹

  # 시민의회 그룹은 모두 role빠띠로 리다이렉트됩니다
  constraints(subdomain: 'citizensassembly') do
    get '/posts/:id', to: redirect(subdomain: '', path: '/posts/%{id}')
    get '/', to: redirect(subdomain: '', path: '/p/role')
    match '*path', to: redirect(subdomain: '', path: '/p/role'), via: :all
  end

  # 덕업넷 그룹은 일반 빠띠로 리다이렉트됩니다
  constraints(subdomain: 'duckup') do
    get '/p/:slug/*path', to: redirect(subdomain: '', path: '/p/%{slug}/%{path}')
    get '/', to: redirect(subdomain: '')
    match '*path', to: redirect(subdomain: nil, path: '%{path}'), via: :all
  end

  constraints(IndieGroupRouteConstraint.new) do
    authenticated :user do
      root 'dashboard#index', as: :dashboard_root
    end
  end
  root 'issues#home'
  get '/g/:group_slug/:parti_slug', to: redirect('https://%{group_slug}.parti.xyz/p/%{parti_slug}')
  get '/robots.:format', to: 'pages#robots'

  resources :users, except: :show do
    collection do
      get 'access_token'
      get 'pre_sign_up'
      get 'email_sign_in'
      put 'valid_email'
      put 'invalid_email'
    end
  end
  unless Rails.env.production?
    get 'kill_me', to: 'users#kill_me'
  end

  class MergedIssueRouteConstraint
    def matches?(request)
      group = fetch_group(request) || Group.indie
      params = request.params
      MergedIssue.exists?(source_slug: params[:slug], source_group_slug: group.slug)
    end
  end

  # 통합 빠띠
  get '/p/:slug/', to: redirect { |path_params, request|
    group = fetch_group(request) || Group.indie
    "/p/#{MergedIssue.find_by(source_slug: params[:slug], source_group_slug: group.slug).issue.slug}"
  }, constraints: MergedIssueRouteConstraint.new
  get '/p/:slug/*path', to: redirect { |path_params, request|
    group = fetch_group(request) || Group.indie
    merged_issue = MergedIssue.find_by(source_slug: params[:slug], source_group_slug: group.slug)
    "/p/#{merged_issue.issue.slug}/#{params[:path]}"
  }, constraints: MergedIssueRouteConstraint.new

  # 구 talk/opinion/note/article 주소를 신 post로 이동
  get 'talks/:id', to: 'redirects#talk'
  get 'opinions/:id', to: 'redirects#opinion'
  get 'notes/*path', to: redirect('https://parti.xyz')
  get 'articles/*path', to: redirect('https://parti.xyz')

  resources :parties, as: :issues, controller: 'issues' do
    member do
      delete :remove_logo
      delete :remove_cover
      get :destroy_form
    end
    collection do
      get :indies
      get :exist
      get :search_by_tags
      post :merge
    end
    resources :members do
      put :organizer, on: :collection
      delete :organizer, on: :collection
      delete :cancel, on: :collection
      delete :ban, on: :collection
    end
    resources :member_requests do
      post :accept, on: :collection
      delete :reject, on: :collection
    end
  end

  concern :upvotable do
    resources :upvotes do
      delete :cancel, on: :collection
    end
  end

  resources :posts, concerns: :upvotable do
    shallow do
      resources :comments, concerns: :upvotable
      resources :votes
    end
    member do
      get 'poll_social_card'
      get 'survey_social_card'
      get 'modal'
      get 'images'
      post 'pin'
      delete 'unpin'
      get 'readers'
      get 'unreaders'
      put 'read'
      get 'more_comments'
      get 'wiki'
      patch 'wiki', to: 'posts#update_wiki'
      get 'edit_decision'
      patch 'update_decision'
      get 'decision_histories'
      namespace :wiki, module: nil, controller: "wikis" do
        patch 'purge'
        patch 'activate'
        patch 'inactivate'
        get 'histories'
      end
    end
    collection do
      get 'new_wiki'
    end
  end
  post 'feedbacks', to: 'feedbacks#create'
  resources :options

  resources :polls do
    shallow do
      resources :votings
    end
  end
  get 'links_or_files', to: 'links_or_files#index'
  get 'polls_or_surveys', to: 'polls_or_surveys#index'
  get 'wikis', to: 'wikis#index'

  resources :relateds
  resources :messages
  resources :invitations

  namespace :group do
    resources :members do
      collection do
        put :organizer
        delete :organizer
        delete :ban
        delete :cancel
        post :admit
        get :new_admit
        get :edit_magic_link
        post :magic_link
        delete :delete_magic_link
        get :magic_form
        post :magic_join
        post :update_profile
      end
    end
    resources :member_requests do
      post :accept, on: :collection
      delete :reject, on: :collection
    end
    resources :managements

    namespace :eduhope do
      resources :members do
        collection do
          post :admit
        end
      end
    end
  end

  get 'file_source/:id/download', to: "file_sources#download", as: :download_file_source

  get '/dashboard', to: "dashboard#index", as: 'dashboard'
  get '/dashboard/intro', to: "dashboard#intro", as: 'dashboard_intro'
  get '/dashboard/new_posts_count', to: "dashboard#new_posts_count", as: 'new_dashboard_posts_count'

  get '/c/change2020', to: redirect(subdomain: 'change', path: '/'), constraints: { subdomain: '' }
  get '/c/vplatform', to: redirect(path: '/')

  %w(to-make-it-alive peacebridge gameisculture change-univeristy changebakkum-femi dignity wishforgoodjob politics21 wsc).each do |slug|
    get "/p/#{slug}", to: redirect(subdomain: 'change', path: "/p/#{slug}"), constraints: { subdomain: '' }
  end

  get "/p/innovators-declaration", to: redirect(subdomain: 'innovators', path: "/p/innovators-declaration"), constraints: { subdomain: '' }

  get '/p/:slug', to: "issues#slug_home", as: 'slug_issue'
  get '/p/:slug/references', to: "issues#slug_links_or_files", as: 'slug_issue_links_or_files'
  get '/p/:slug/wikis', to: "issues#slug_wikis", as: 'slug_issue_wikis'
  get '/p/:slug/polls', to: redirect('/p/%{slug}/polls_or_surveys')
  get '/p/:slug/polls_or_surveys', to: "issues#slug_polls_or_surveys", as: 'slug_issue_polls_or_surveys'
  get '/p/:slug/members', to: "issues#slug_members", as: 'slug_issue_users'
  get '/p/:slug/new_posts_count', to: "issues#new_posts_count", as: 'new_issue_posts_count'

  get '/u/:slug', to: "users#posts", as: 'slug_user'

  get '/about', to: "pages#about", as: 'about'
  get '/privacy', to: "pages#privacy", as: 'privacy'
  get '/service', to: "pages#service", as: 'service'
  get '/terms', to: "pages#terms", as: 'terms'
  if Rails.env.development?
    get '/score', to: "pages#score"
    get '/analyze', to: "pages#analyze"
  end

  get '/tags/:name', to: "tags#show", as: :tag
  get '/categories/:slug', to: "categories#show", as: :category

  authenticate :user, lambda { |u| u.admin? } do
    get '/test/summary', to: "users#summary_test"
  end

  get '/dev/components', to: 'pages#components'

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/devel/emails"
  end

  namespace :'mobile_app' do
    get 'start', to: 'pages#start'
    get 'sessions/restore', to: 'sessions#restore', as: :restore_sessions
    get 'sessions/setup', to: 'sessions#setup', as: :setup_sessions
    get 'sessions/teardown', to: 'sessions#teardown', as: :teardown_sessions
  end

  namespace :admin do
    root to: 'monitors#index'
    resources :issues do
      post 'merge', on: :collection
      post 'freeze', on: :collection
    end

    resources :roles do
      collection do
        post :add
        delete :remove
      end
    end
    resources :users do
      collection do
        get 'all_email'
        get 'stat'
      end
    end
    resources :groups
    resources :blinds
    resources :active_issue_stats
    resources :manage_landing_pages

    get :new_notice_email, to: 'notice_email#new'
    post :deliver_notice_email, to: 'notice_email#deliver'
  end
end
