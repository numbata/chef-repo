#
# Cookbook Name:: gnomiki.ru
# Recipe:: default
#

include_recipe "nginx::source"

template "/etc/nginx/conf.d/custom_log.conf" do
  source "custom_log.conf.erb"
  notifies :restart, resources(:service => 'nginx')
end

template "/etc/nginx/sites-enabled/default.conf" do
  source "default.conf.erb"
  notifies :restart, resources(:service => 'nginx')
end
