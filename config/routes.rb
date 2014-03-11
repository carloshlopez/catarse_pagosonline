CatarsePagosonline::Engine.routes.draw do
  namespace :payment do
    get '/pagosonline/:id/review' => 'pagosonline#review', :as => 'review_pagosonline'
    post '/pagosonline/notifications' => 'pagosonline#ipn',  :as => 'ipn_pagosonline'
    post '/pagosonline/:id/notifications' => 'pagosonline#notifications',  :as => 'notifications_pagosonline'
    get '/pagosonline/:id/success'       => 'pagosonline#success',        :as => 'success_pagosonline'
    post '/pagosonline/:id/cancel'        => 'pagosonline#cancel',         :as => 'cancel_pagosonline'
  end
end
