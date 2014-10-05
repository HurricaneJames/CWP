source 'https://rubygems.org'

gem 'rails', '4.1.4'

gem 'sqlite3'

gem 'sass-rails', '~> 4.0.3'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'therubyracer',  platforms: :ruby

gem 'jquery-rails'
# gem 'js-routes'

gem 'versionist'

gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0',          group: :doc

gem 'spring',        group: :development

gem 'foundation-rails', '~> 5.4'
# gem 'react-rails', '~> 0.11.1'
gem 'react-rails', '~> 1.0.0.pre', github: 'reactjs/react-rails'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

group :development do
  gem 'thin'
  gem 'quiet_assets'
end

group :developemnt, :test do
  gem 'spring-commands-rspec'
  gem 'rspec-rails'
  gem 'guard-rspec'
  gem 'capybara'
  gem 'fabrication'
  gem 'rb-fsevent' if `uname` =~ /Darwin/
end