Rails.application.routes.draw do
  sso_devise
  root 'pages#home'
  resources :articles
end
