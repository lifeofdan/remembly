defmodule Remembly.Remember do
  use Ash.Domain, extensions: [AshJsonApi.Domain]

  json_api do
    routes do
      # in the domain `base_route` acts like a scope
      base_route "/links", Remembly.Remember.Link do
        get :read
        index :read
        post :create
      end
    end
  end

  resources do
    resource Remembly.Remember.Link
  end
end
