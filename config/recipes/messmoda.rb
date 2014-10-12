namespace :easytimelog do
  # desc "Link the current production database to the new deploy"
  # task :link_database_file do
  #   run "ln -nsf #{shared_path}/production.sqlite3 #{release_path}/db/production.sqlite3"
  # end
  # before "deploy:finalize_update", "thoriumarts:link_database_file"

  # desc "Setup the production database and seed images"
  # task :seed_system do
  #   run "scp -r #{seed_files}/uploads #{shared_path}/system/" do |ch, stream, data|
  #     if data =~ /Are you sure you want to continue connecting/
  #       puts "*** *** SENDING YES"
  #       ch.send_data("yes\n")
  #     else
  #       Capistrano::Configuration.default_io_proc.call(ch, stream, data)
  #     end
  #   end 
  #   run "scp #{seed_files}/production.sqlite3 #{shared_path}"
  # end
  # after "deploy:setup", "thoriumarts:seed_system"
end