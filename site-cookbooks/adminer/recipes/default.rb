# TODO destination path
#include_recipe "sites"

yasecret = data_bag_item('secrets', 'adminer')

sites_php "adminer" do
  action [:install]
  domain "mysql.subbota.net"
end

cookbook_file "/var/www/adminer/shared/adminer.php" do
  source "adminer.php"
  mode 0777
  owner "www-data"
end

template "/var/www/adminer/current/public/index.php" do
  source "index.php.erb"
  mode 0777
  owner "www-data"
end

template "/var/www/adminer/shared/htpasswd" do
  source "htpasswd.erb"
  mode 0777
  owner "www-data"
  variables ({
    :secret => yasecret['password']
  })
end
