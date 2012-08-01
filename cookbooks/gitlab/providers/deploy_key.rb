#
# Cookbook Name:: gitlab
# Provider:: deploy_key
#
# Copyright 2012, One.OS
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

def escape(name)
  name.downcase.gsub(/\s/, '_')
end

action :add do
  key_name     = new_resource.name
  project_name = new_resource.project_name
  Chef::Log.info "Adding deploy key '#{key_name}' to Gitlab project '#{project_name}'"

  # Hack around in Gitlab
  add_deploy_key_script_path =
    "#{node.gitlab.app_home}/add_deploy_key_#{escape(key_name)}_to_#{escape(project_name)}.rb"
  file add_deploy_key_script_path do
    owner node['gitlab']['user']
    group node['gitlab']['group']
    mode  0755
    content <<-CODE
      require "#{node.gitlab.app_home}/config/boot"
      require "#{node.gitlab.app_home}/config/application"
      Rails.env = 'production'
      Rails.application.require_environment!

      project = ::Project.where(name: "#{project_name}")[0]

      unless project.deploy_keys.where(key: "#{new_resource.public_key}")
        key = project.deploy_keys.new(title: "#{key_name}", key: "#{new_resource.public_key}")
        key.save!
      end
    CODE
  end

  execute ::File.basename(add_deploy_key_script_path) do
    cwd     node['gitlab']['app_home']
    command "bundle exec ruby #{add_deploy_key_script_path}"
    user  node['gitlab']['user']
    group node['gitlab']['group']
  end
end
