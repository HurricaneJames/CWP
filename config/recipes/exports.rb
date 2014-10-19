namespace :exports do
  desc "Setup environment variables for system"
  task :install, roles: :app do
    template "exports.erb", "/tmp/exports"
    run "#{sudo} echo /tmp/exports >> #{user_home}/.profile"
    run "#{sudo} rm -f /tmp/exports"
  end
  after "deploy:install", "exports:install"
end