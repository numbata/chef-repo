vagrant_lucid_image = "vagrant_lucid.box"

gem_package "bundle" do
  action :install
end

gem_package "vagrant" do
  action :install
end

directory node['vagrant_boxes']['path'] do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

need_iptables = false

node['vagrant_boxes']['boxes'].each do |box|
  vagrant_boxes_box box['name'] do
    action [:install, :up]
    source box.has_key?('source') ? box['source'] : node['vagrant_boxes']['source']
  end
  need_iptables = true if box.has_key?('public_ip')
end

if need_iptables
  Chef::Log.info("Reconfigure iptables")
  include_recipe 'iptables'
  iptables_rule "vagrant" do
    variables ({
      :boxes => node['vagrant_boxes']['boxes']
    })
  end

  Chef::Log.info("Reconfigure iptables_forward")
  execute "iptables_forward" do
    user "root"
    command "echo '1' > /proc/sys/net/ipv4/ip_forward"
    only_if "cat /proc/sys/net/ipv4/ip_forward | grep -q 0"
  end
end

template "#{node['vagrant_boxes']['path']}/Vagrantfile" do
  source "Vagrantfile.erb"
  variables ({
    :boxes => node['vagrant_boxes']['boxes']
  })
end

execute "vagrant_reload" do
  user "root"
  cwd node['vagrant_boxes']['path']
  command "vagrant reload"
  only_if "vagrant status | grep -q running"
end

execute "vagrant_up" do
  user "root"
  cwd node['vagrant_boxes']['path']
  command "vagrant up"
  not_if "vagrant status | grep -q running"
end
