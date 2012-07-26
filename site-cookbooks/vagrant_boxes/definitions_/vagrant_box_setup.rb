#define :vagrant_box_setup do
#  remote_file "#{node['vagrant-box']['path']}/vagrant-#{params[:name]}" do
#    source "#{Chef::Config[:file_cache_path]}/vagrant_lucid.box"
#    mode 0644
#    action :create_if_missing
#    notifies :run, "vagrant_box_bootstrap"
#  end
#
#  execute "vagrant_box_bootstrap" do
#    cwd node['vagrant-box']['path']
#    command "vagrant box add #{params[:name]} #{node['vagrant-box']['path']}/vagrant-#{params[:name]}"
#    command "vagrant init #{params[:name]}"
#  end
#end
