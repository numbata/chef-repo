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
