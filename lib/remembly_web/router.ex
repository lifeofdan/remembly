defmodule RememblyWeb.Router do
  alias RememblyWeb.InteractionsController
  use RememblyWeb, :router

  pipeline :graphql do
    plug AshGraphql.Plug
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RememblyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RememblyWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/messages", ShowMessages, :index
    live "/websites", ShowWebsites, :index
    live "/memories", ShowMemories, :index
  end

  scope "/gql" do
    pipe_through [:graphql]

    forward "/playground", Absinthe.Plug.GraphiQL,
      schema: Module.concat(["RememblyWeb.GraphqlSchema"]),
      socket: Module.concat(["RememblyWeb.GraphqlSocket"]),
      interface: :simple

    forward "/", Absinthe.Plug, schema: Module.concat(["RememblyWeb.GraphqlSchema"])
  end

  scope "/interactions" do
    pipe_through :api

    post "/", InteractionsController, :index
  end

  scope "/api" do
    pipe_through :api

    forward "/swaggerui",
            OpenApiSpex.Plug.SwaggerUI,
            path: "/api/open_api",
            default_model_expand_depth: 4

    forward "/redoc",
            Redoc.Plug.RedocUI,
            spec_url: "/api/open_api"

    forward "/", RememblyWeb.JsonApiRouter
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:remembly, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RememblyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
