#
# Cookbook Name:: yabackup
# Recipe:: default
#
package "davfs2"

directory node['yabackup']['mountdir'] do
  owner node['yabackup']['owner_user']
  group node['yabackup']['owner_group']
  mode "0755"
  action :create
  recursive true
end

yasecret = data_bag_item('secrets', node['yabackup']['secrets'])

execute "check_yadisk_pass" do
  user node['yabackup']['owner_user']
  command "echo '#{node['yabackup']['webdav_url']} #{yasecret['username']} #{yasecret['password']}' >> /etc/davfs2/secrets"
  not_if "grep -q '#{node['yabackup']['webdav_url']}' /etc/davfs2/secrets"
end

mount node['yabackup']['mountdir'] do
  fstype "davfs"
  device node['yabackup']['webdav_url']
  options "rw,_netdev,users,exec"
  action [:mount, :enable]
  not_if "mountpoint -q #{node['yabackup']['mountdir']}"
end
