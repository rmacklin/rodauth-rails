class RodauthApp < Rodauth::Rails::App
  configure do
    enable :create_account, :verify_account, :verify_account_grace_period,
      :login, :remember, :logout, :active_sessions,
      :reset_password, :change_password, :change_password_notify,
      :change_login, :verify_login_change,
      :close_account, :lockout

    rails_controller { RodauthController }

    before_rodauth do
      if param_or_nil("raise")
        raise NotImplementedError
      elsif param_or_nil("fail")
        fail "failed"
      end
    end

    account_status_column :status
    account_unverified_status_value "unverified"
    account_open_status_value "verified"
    account_closed_status_value "closed"

    email_subject_prefix "[RodauthTest] "
    email_from "noreply@rodauth.test"

    require_login_confirmation? false
    verify_account_set_password? false
    extend_remember_deadline? true
    max_invalid_logins 3

    after_login { remember_login }

    logout_redirect "/"
    verify_account_redirect { login_redirect }
    reset_password_redirect { login_path }
  end

  configure(:admin) do
    prefix "/admin"
  end

  configure(:json, json: true) do
    enable :jwt, :create_account, :verify_account
    only_json? true
    rails_controller { ActionController::API } if ActionPack.version >= Gem::Version.new("5.0")
    prefix "/json"
    jwt_secret "secret"
    account_status_column :status
  end

  route do |r|
    rodauth.load_memory

    r.rodauth
    r.on("admin") { r.rodauth(:admin) }
    r.on("json")  { r.rodauth(:json) }

    if r.path == "/auth1"
      rodauth.require_authentication
    end
  end
end
