#
# Cookbook Name:: gitlab
# Recipe:: default
#
# Copyright 2012, Gerald L. Hevener Jr., M.S.
# Copyright 2012, Eric G. Wolfe
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

%w{ ruby_build gitlab::gitolite build-essential
    readline sudo openssh xml zlib python::pip
    redisio::install redisio::enable sqlite }.each do |dependency|
  include_recipe dependency
end

# There are problems deploying on Redhat provided rubies.
# We'll use Fletcher Nichol's slick ruby_build cookbook to compile a Ruby.
if node['gitlab']['install_ruby'] !~ /package/
  ruby_build_ruby node['gitlab']['install_ruby'] 

  # Drop off a profile script.
  template "/etc/profile.d/gitlab.sh" do
    owner "root"
    group "root"
    mode 0755
  end

  # Set PATH for remainder of recipe.
  ENV['PATH'] = "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/usr/local/ruby/#{node['gitlab']['install_ruby']}/bin"
end

# Install required packages for Gitlab
node['gitlab']['packages'].each do |pkg|
  package pkg
end

# Install sshkey gem into chef
chef_gem "sshkey" do
  action :install
end

# Install required Ruby Gems for Gitlab
%w{ charlock_holmes bundler }.each do |gempkg|
  gem_package gempkg do
    action :install
  end
end

# Install pygments from pip
python_pip "pygments" do
  action :install
end

# Add the gitlab user
user node['gitlab']['user'] do
  comment "Gitlab User"
  home node['gitlab']['home']
  shell "/bin/bash"
  supports :manage_home => true
end

# Fix home permissions for nginx
directory node['gitlab']['home'] do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0755
end

# Add the gitlab user to the "git" group
group node['gitlab']['git_group'] do
  members node['gitlab']['user']
end

# Create a $HOME/.ssh folder
directory "#{node['gitlab']['home']}/.ssh" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0700
end

# Generate and deploy ssh public/private keys
Gem.clear_paths
require 'sshkey'
gitlab_sshkey = SSHKey.generate(:type => 'RSA', :comment => "#{node['gitlab']['user']}@#{node['fqdn']}")

# Save public_key to node, unless it is already set.
ruby_block "save node data" do
  block do
    node.save
  end
  not_if { Chef::Config[:solo] }
  action :create
end

file "#{node['gitlab']['home']}/.ssh/id_rsa" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0600
  content gitlab_sshkey.private_key
  not_if { File.exists?("#{node[:gitlab][:home]}/.ssh/id_rsa") }
end

file "#{node['gitlab']['home']}/.ssh/id_rsa.pub" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  content gitlab_sshkey.ssh_public_key
  not_if { File.exists?("#{node[:gitlab][:home]}/.ssh/id_rsa.pub") }
end


# Configure gitlab user to auto-accept localhost SSH keys
template "#{node['gitlab']['home']}/.ssh/config" do
  source "ssh_config.erb"
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
end

gitlab_is_already_authorized = "grep -q '#{node['gitlab']['user']}' #{node['gitlab']['git_home']}/.ssh/authorized_keys"

# Render public key template for gitolite user
file "#{node['gitlab']['git_home']}/gitlab.pub" do
  owner node['gitlab']['git_user']
  group node['gitlab']['git_group']
  mode 0644
  content gitlab_sshkey.ssh_public_key
  not_if gitlab_is_already_authorized
end

# Sorry for this ugliness.
# It seems maybe something is wrong with the 'gitolite setup' script.
# This was implemented as a workaround.
execute "install-gitlab-key" do
  command "su - #{node['gitlab']['git_user']} -c 'perl #{node['gitlab']['gitolite_home']}/src/gitolite setup -pk #{node['gitlab']['git_home']}/gitlab.pub'"
  user "root"
  cwd node['gitlab']['git_home']
  not_if gitlab_is_already_authorized
end

# Clone Gitlab repo from github
git node['gitlab']['app_home'] do
  repository node['gitlab']['gitlab_url']
  reference node['gitlab']['gitlab_branch']
  action :checkout
  user node['gitlab']['user']
  group node['gitlab']['group']
end

# Render gitlab config file
template "#{node['gitlab']['app_home']}/config/gitlab.yml" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
end

# Link sqlite example config file to database.yml
link "#{node['gitlab']['app_home']}/config/database.yml" do
  to "#{node['gitlab']['app_home']}/config/database.yml.sqlite"
  owner node['gitlab']['user']
  group node['gitlab']['group']
  link_type :hard
end

# Install Gems with bundle install
execute "gitlab-bundle-install" do
  command "bundle install --without development test --deployment"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  environment({ 'LANG' => "en_US.UTF-8", 'LC_ALL' => "en_US.UTF-8" })
  not_if { File.exists?("#{node['gitlab']['app_home']}/vendor/bundle") }
end

directory "#{node['gitlab']['app_home']}/tmp" do
  user node['gitlab']['user']
  group node['gitlab']['group']
end

execute "precompile-gitlab-assets" do
  command "bundle exec rake assets:precompile RAILS_ENV=production"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  not_if { File.exists?("#{node['gitlab']['app_home']}/tmp/cache/assets") }
end

gitlab_database_exists = File.exists?("#{node['gitlab']['app_home']}/db/production.sqlite3")

execute "setup-gitlab-database" do
  command "bundle exec rake gitlab:app:setup RAILS_ENV=production"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  not_if { gitlab_database_exists }
end

execute "migrate-gitlab-database" do
  command "bundle exec rake db:migrate RAILS_ENV=production"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
end

include_recipe 'gitlab::nginx_unicorn'
