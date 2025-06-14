defmodule Remembly.Remember do
  alias Remembly.Remember.Message
  alias Remembly.Remember.Category
  use Ash.Domain, extensions: [AshJsonApi.Domain]

  json_api do
    routes do
      # in the domain `base_route` acts like a scope
      base_route "/messages", Message do
        get :read
        index :read
        post :create
      end

      base_route "/categories", Category do
        get :read
        index :read
        post :create
      end
    end
  end

  resources do
    resource Message do
      define :message, action: :remember_message
    end

    resource Category do
      define :category, action: :remember_category
    end
  end
end
