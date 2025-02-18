require "roda"
require "rodauth"
require "rodauth/rails/feature"

module Rodauth
  module Rails
    # The superclass for creating a Rodauth middleware.
    class App < Roda
      require "rodauth/rails/app/middleware"
      plugin Middleware

      plugin :hooks
      plugin :render, layout: false

      def self.configure(name = nil, **options, &block)
        unless options[:json] == :only
          require "rodauth/rails/app/flash"
          plugin Flash
        end

        plugin :rodauth, name: name, csrf: false, flash: false, **options do
          # load the Rails integration
          enable :rails

          if options[:json] == :only && ActionPack.version >= Gem::Version.new("5.0")
            rails_controller { ActionController::API }
          else
            rails_controller { ActionController::Base }
          end

          # database functions are more complex to set up, so disable them by default
          use_database_authentication_functions? false

          # avoid having to set deadline values in column default values
          set_deadline_values? true

          # use HMACs for additional security
          hmac_secret { Rodauth::Rails.secret_key_base }

          # evaluate user configuration
          instance_exec(&block)
        end
      end

      before do
        (opts[:rodauths] || {}).each do |name, _|
          if name
            env["rodauth.#{name}"] = rodauth(name)
          else
            env["rodauth"] = rodauth
          end
        end
      end
    end
  end
end
