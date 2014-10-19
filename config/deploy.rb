require "bundler/capistrano"

load "deploy/assets"
load "config/recipes/base"
load "config/recipes/nginx"
load "config/recipes/unicorn"
load "config/recipes/rbenv"
load "config/recipes/postgresql"
load "config/recipes/check"
load "config/recipes/messmoda"

server "messmoda.com", :web, :app, :db, primary: true

set :application, "messmoda.com"
set :user, "deployer"
set :user_home, "/home/#{user}"
set :deploy_to, "#{user_home}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "https://github.com/HurricaneJames/CWP.git"
set :branch, "iteration_1"

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases
