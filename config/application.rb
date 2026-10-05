require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.default_locale = :ja
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Tokyo"
    # Turbo はページ移動を fetch で行う。Rails が付ける Link: rel=preload ヘッダーを、そのたびにブラウザが処理して
    # 「preloaded but not used」の警告が出るため無効にする（CSS は <head> の link で読み込まれる）
    config.action_view.preload_links_header = false
    # config.eager_load_paths << Rails.root.join("extras")
    # config/application.rb
  end
end
