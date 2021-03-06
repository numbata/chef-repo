require 'chef/mixin/shell_out'
require 'chef/mixin/language'

include Chef::Mixin::ShellOut

action :install do
  Chef::Log.info("Setup '#{new_resource.name}' php site")

  root_directory = new_resource.root_directory || "/var/www/#{new_resource.name}"
  public_directory = new_resource.public_directory || "#{root_directory}/current/public/"
  log_directory = new_resource.log_directory || "#{root_directory}shared/log"
  config_directory = "#{root_directory}shared/config"

  [root_directory, log_directory, config_directory].each do |dir|
    directory dir do
      owner "www-data"
      group "www-data"
      action :create
    end
  end

  template "/etc/nginx/sites-available/#{new_resource.name}" do
    source "unicorn.nginx.conf.erb"
    variables :server_name => new_resource.name,
              :server_domain => (new_resource.domain || new_resource.name),
              :root_directory => root_directory,
              :public_directory => public_directory,
              :log_directory => log_directory
  end

  nginx_site new_resource.name do
    enable true
  end

end
