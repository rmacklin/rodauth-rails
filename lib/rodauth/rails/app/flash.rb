module Rodauth
  module Rails
    class App
      # Roda plugin that sets up Rails flash integration.
      module Flash
        def self.load_dependencies(app)
          app.plugin :hooks
        end

        def self.configure(app)
          app.before { request.flash }        # load flash
          app.after  { request.commit_flash } # save flash
        end

        module InstanceMethods
          def flash
            request.flash
          end
        end

        module RequestMethods
          # If the redirect would bubble up outside of the Roda app, the after
          # hook would never get called, so we make sure to commit the flash.
          def redirect(*)
            commit_flash
            super
          end

          def flash
            rails_request.flash
          end

          def commit_flash
            if ActionPack.version >= Gem::Version.new("5.0")
              rails_request.commit_flash
            else
              # ActionPack 4.2 automatically commits flash
            end
          end

          private

          def rails_request
            ActionDispatch::Request.new(env)
          end
        end
      end
    end
  end
end
