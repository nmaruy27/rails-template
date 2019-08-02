# .gitignore
gitignore = '.gitignore'
run "gibo dump macOS Ruby Rails > #{gitignore}" rescue nil
append_file "#{gitignore}", ''
append_file "#{gitignore}", '# Ignore app settings'
append_file "#{gitignore}", 'config/database.yml'
append_file "#{gitignore}", 'config/secrets.yml'
append_file "#{gitignore}", '/public/packs'

######################
# gem install
######################
gem_group :default do
    gem 'hashie'
    gem 'kaminari'
    gem 'activerecord-session_store'
    gem 'active_hash'
    gem 'grape'
    gem 'grape-jbuilder'
    gem 'migration_comments'
    gem 'seed-fu'
    gem 'httparty'
    gem 'activerecord-import'
end

gem_group :development do
    gem 'foreman'
    gem 'capistrano'
    gem 'capistrano-rails'
    gem 'capistrano-bundler'
    gem 'capistrano3-puma'
    gem 'capistrano-rbenv'
end

gem_group :development, :test do
    gem 'rspec-rails'
    gem 'pry-rails'
    gem 'pry-doc'
    gem 'pry-byebug'
    gem 'capybara'
end

run 'bundle install --path=vendor/bundle -j4'

# gem task
generate 'rspec:install'
generate 'friendly_id'
generate 'active_record:session_migration'


######################
# other settings
######################

# session settings
create_file 'config/initializers/session_store.rb', <<SESSION
# Be sure to restart your server when you modify this file.
Rails.application.config.session_store :active_record_store, key: '_sess'
SESSION

# typescript
create_file 'tsconfig.json', <<EOF
{
  "compilerOptions": {
    "target": "es5",
    "module": "es2015",
    "lib": ["es2016", "dom"],
    "sourceMap": true,
    "allowJs": true,
    "jsx": "react",
    "moduleResolution": "node"
  },
  "exclude": [
    "node_modules",
    "build",
    "scripts",
    "acceptance-tests",
    "jest",
    "src/setupTests.ts",
    "vendor"
  ]
}
EOF

# capistrano
run 'bundle exec cap install'
insert_into_file 'Capfile', <<CAP, after: '# require "capistrano/passenger"'

require 'capistrano/bundler'
require 'capistrano/puma'
install_plugin Capistrano::Puma
require 'capistrano/rails/migrations'
require 'capistrano/rbenv'
CAP

# application config
insert_into_file 'config/application.rb', <<APP, after: '# -- all .rb files in that directory are automatically loaded.'

    # rspec
    config.generators do |g|
      g.test_framework :rspec,
                       fixtures: true,
                       view_specs: false,
                       helper_specs: false,
                       routing_specs: false,
                       controller_specs: true,
                       request_specs: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end

    # set activerecord timezone to japan
    config.active_record.default_timezone = :local

    # set locale to ja
    config.i18n.default_locale = :ja

    # set timezone to japan
    config.time_zone = 'Tokyo'

    # for Grape Api
    config.paths.add File.join('app', 'apis'), glob: File.join('**', '*.rb')
    config.autoload_paths += Dir[Rails.root.join('app', 'apis', '*')]

    # for Grape-jbuilder
    config.middleware.use(Rack::Config) do |env|
      env['api.tilt.root'] = Rails.root.join 'app', 'views', 'apis'
    end
APP


# foreman
create_file 'Procfile', <<PROC
rails: rails s -p 3000
PROC

after_bundle do
  # git
  git :init
  git add: '.'
  git commit: "-m 'initial commit'"
end
