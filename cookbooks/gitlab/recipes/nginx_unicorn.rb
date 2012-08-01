# encoding: utf-8

package 'nginx'

# Render unicorn template
template "#{node['gitlab']['app_home']}/config/unicorn.rb" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
end

package 'daemon'

# Render unicorn_rails init script
template "/etc/init.d/unicorn_rails" do
  owner "root"
  group "root"
  mode 0755
  source "unicorn_rails.init.erb"
end

# Start unicorn_rails and nginx service
%w{ unicorn_rails nginx }.each do |svc|
  service svc do
    action [ :start, :enable ]
  end
end

file("/etc/nginx/sites-enabled/default") { action :delete }

# Render nginx default vhost config
template "/etc/nginx/conf.d/default.conf" do
  owner "root"
  group "root"
  mode 0644
  source "nginx.default.conf.erb"
  notifies :restart, "service[nginx]", :delayed
end

template "/etc/nginx/sites-available/gitlab" do
  owner "root"
  group "root"
  mode 0644
  source "nginx.gitlab.conf.erb"

  variables(
    :hostname => "gitlab.#{node.domain}"
  )

  notifies :restart, "service[nginx]", :delayed
end

link("/etc/nginx/sites-enabled/gitlab") { to "/etc/nginx/sites-available/gitlab"}
