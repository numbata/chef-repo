#
# Cookbook Name:: gnomiki.ru
# Recipe:: default
#
root_directory = "/var/www/gnomiki.ru"
public_directory = "#{root_directory}/current/"
log_directory = "#{root_directory}/shared/log/"

[root_directory, public_directory, log_directory].each do |dir|
  directory dir do
    recursive true
    owner "www-data"
    group "www-data"
  end
end

template "/etc/nginx/sites-enabled/gnomiki.ru.conf" do
  source "gnomiki.ru.conf.erb"
  variables :server_name => 'www.gnomiki.ru gnomiki.ru',
            :public_directory => public_directory,
            :log_directory => log_directory

  notifies :restart, resources(:service => 'nginx')
end

chef_gem "mysql"
mysql_database "gnomiki" do
  connection ({:host => "localhost", :username => "root"})
  action :create
end

cron "gnomiki_backup" do
  hour "5"
  minute "0"
  command "tar czfm #{node['yabackup']['mountdir']}/gnomiki.ru/$(date +%Y%m%%d-%H%M%S).tar.gz #{public_directory}/"
end
