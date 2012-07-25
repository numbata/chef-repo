template "/etc/php5/conf.d/timezone.ini" do
  source "timezone.ini.erb"
  owner "root"
  group "root"
  mode "0644"
end
