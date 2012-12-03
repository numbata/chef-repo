#
# Cookbook Name:: yabackup
# Recipe:: default
#
package "davfs2"

directory "#{node['yabackup']['mountdir']}" do
  owner "#{node['yabackup']['owner_user']}"
  group "#{node['yabackup']['owner_group']}"
  mode "0755"
  action :create
  recursive true
end

yasecret = data_bag_item('secrets', "#{node['yabackup']['secrets']}")

execute "check_yadisk_pass" do
  user "#{node['yabackup']['owner_user']}"
  command "echo '#{node['yabackup']['webdav_url']} #{yasecret['username']} #{yasecret['password']}' >> /etc/davfs2/secrets"
  not_if "grep -q '#{node['yabackup']['webdav_url']}' /etc/davfs2/secrets"
end

mount "/mnt/yabackup/" do
  fstype "davfs"
  device "#{node['yabackup']['webdav_url']}"
  options "rw"
  action [:mount, :enable]
end
