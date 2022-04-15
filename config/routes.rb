
## CONSONANTS = ["a", "ka", "sa", "ta", "na", "ha", "ma", "ya", "ra", "wa", "zz"]

Rails.application.routes.draw do
  get '/index', to: 'top#index'

  root to: 'top#index'


  resources :index_pages, only: [] do
    collection do
      get 'index_top'

      get 'person_:id', to: 'index_pages#person_index', constraints: { id: /[kstnhmyrw]?a|zz/ }
      get 'person:id', to: 'index_pages#person_show', constraints: { id: /\d+/ }
    end
  end

  resources :cards, only: [] do
    member do
      get 'card:card_id', to: 'cards#card_show', constraints: { card_id: /\d+/ }
    end
  end
end
