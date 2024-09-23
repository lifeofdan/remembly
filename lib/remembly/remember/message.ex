defmodule Remembly.Remember.Message do
  use Ash.Resource,
    otp_app: :remembly,
    domain: Remembly.Remember,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource]

  json_api do
    type "message"
  end

  postgres do
    table "messages"
    repo Remembly.Repo
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    create :remember_message do
      accept [:content]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :content, :string, allow_nil?: false

    timestamps()
  end
end
