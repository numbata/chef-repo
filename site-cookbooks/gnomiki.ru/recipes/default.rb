#
# Cookbook Name:: gnomiki.ru
# Recipe:: default
#
root_directory = "/var/www/gnomiki.ru"
public_directory = "#{root_directory}/www"
log_directory = "#{root_directory}/log"

["#{root_directory}" "#{public_directory}" "#{log_directory}"].each do |dir|
  directory "#{dir}" do
    recursive true
    owner www-data
    group www-data
  end
end

git "#{public_directory}" do
  repository "git@git.subbota.net:gnomiki_ru.git"
  reference "master"
  action :sync
  user www-data
  group www-data
end

template "/etc/nginx/conf.d/gnomiki.ru.conf" do
  source "gnomiki.ru.conf.erb"
  variables :server_name => 'www.gnomiki.ru gnomiki.ru',
            :root_directory => "#{root_directory}",
            :public_directory => "#{public_directory}",
            :log_directory => "#{log_directory}"

  notifies :restart, resources(:service => 'nginx')
end

mysql_database "gnomiki" do
  action :create
end

cron "gnomiki_backup" do
  hour "5"
  minute "0"
  command "tar czfm #{node['yabackup']['mountdir']}/gnomiki.ru/$(date +%Y%m%%d-%H%M%S).tar.gz #{public_directory}/"
end
