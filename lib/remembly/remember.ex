defmodule Remembly.Remember do
  alias Remembly.Remember.Message
  use Ash.Domain, extensions: [AshJsonApi.Domain]

  json_api do
    routes do
      # in the domain `base_route` acts like a scope
      base_route "/messages", Message do
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
  end
end
