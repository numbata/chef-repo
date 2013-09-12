require 'chef/mixin/shell_out'
require 'chef/mixin/language'

include Chef::Mixin::ShellOut

action :install do
  Chef::Log.info("Setup '#{new_resource.name}' vagrant box from '#{new_resource.source}' [ vagrant box list | grep -qE '^#{new_resource.name}$' ]")
  execute "vagrant_boxes_add_#{new_resource.name}" do
    user "root"
    cwd node['vagrant_boxes']['path']
    command "vagrant box add #{new_resource.source} #{node['vagrant_boxes']['sources'][new_resource.source]}"
    #only_if do
    #  node['vagrant_boxes']['sources'].has_key?(new_resource.source)
    #end
    not_if "vagrant box list | grep -E \"^#{new_resource.source}\""
  end

  new_resource.updated_by_last_action(true)
end

action :up do
  Chef::Log.info("Up '#{new_resource.name}' vagrant box [ vagrant status #{new_resource.name} | grep -q -E '#{new_resource.name}\\s+running' ]")
  execute "vagrant_boxes_up_#{new_resource.name}" do
    user "root"
    cwd node['vagrant_boxes']['path']
    command "vagrant up #{new_resource.name}"
    only_if do
      ::File.exists?(::File.join(node['vagrant_boxes']['path'],'Vagrantfile'))
    end
    not_if "vagrant status #{new_resource.name} | grep -E '#{new_resource.name}\\s+running'"
  end

  new_resource.updated_by_last_action(true)
end
