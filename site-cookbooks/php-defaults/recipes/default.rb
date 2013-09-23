template "/etc/php5/conf.d/timezone.ini" do
  source "timezone.ini.erb"
  owner "root"
  group "root"
  mode "0644"
end

template "/usr/local/etc/php-fpm.conf" do
  source "php-fpm.conf.erb"
  owner "root"
  group "root"
  mode "0644"
end

directory "/var/www/fpm.d/" do
  owner "www-data"
  group "www-data"
  action :create
end

service "php-fpm" do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action :nothing
end

template "/etc/init.d/php-fpm" do
  source "php-fpm.initd.erb"
  owner "root"
  group "root"
  mode "0755"
  notifies :enable, "service[php-fpm]"
  notifies :start, "service[php-fpm]"
end
