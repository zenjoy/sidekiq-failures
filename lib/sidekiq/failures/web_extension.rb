module Sidekiq
  module Failures
    module WebExtension

      def self.registered(app)
        app.helpers do
          def find_template_with_failures(name, *a, &b)
            if !settings.views.is_a?(Array)
              settings.views = Array(settings.views).flatten
            end
            if !settings.views.include?(File.expand_path("../views/", __FILE__))
              settings.views << File.expand_path("../views/", __FILE__)
            end
            settings.views.each { |v| find_template_without_failures(name, *a, &b) }
          end
          alias_method_chain :find_template, :failures
        end

        app.get "/failures" do
          @count = (params[:count] || 25).to_i
          (@current_page, @total_size, @messages) = page("failed", params[:page], @count)
          @messages = @messages.map { |msg| Sidekiq.load_json(msg) }

          slim :failures
        end

        app.post "/failures/remove" do
          Sidekiq.redis do |redis|
            redis.del("failed")
            redis.set("stat:failed", 0)
          end

          redirect "#{root_path}failures"
        end
      end
    end
  end
end
