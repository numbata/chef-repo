#
# Cookbook Name:: yabackup
# Recipe:: default
#
package davfs2

directory "/mnt/backup/" do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

yasecret = data_bag_item('secrets', 'yabackup')

execute "check_yadisk_pass" do
  user "root"
  command "echo 'https://webdav.yandex.ru/ #{yasecret.username} #{yasecret.password}' >> /etc/davfs2/secrets"
  not_if "grep -q 'webdav.yandex.ru' /etc/davfs2/secrets"
end

mount "/mnt/backup/" do
  fstype "davfs"
  device "https://webdav.yandex.ru"
  options "rw"
  action [:mount, :enable]
end
