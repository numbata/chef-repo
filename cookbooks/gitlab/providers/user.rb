#
# Cookbook Name:: gitlab
# Provider:: user
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

# This file generates the class Chef::Resource::GitlabUser

action :add do
  Chef::Log.info "Adding user '#{new_resource.name}' to Gitlab"

  # Hack around in Gitlab
  new_gitlab_user = @new_resource
  add_gitlab_user_script_path = "#{node.gitlab.app_home}/add_gitlab_user_#{new_gitlab_user.name.downcase.gsub(/\s/, '_')}.rb"
  file add_gitlab_user_script_path do
    owner node['gitlab']['user']
    group node['gitlab']['group']
    mode  0755
    content <<-CODE
      #!/usr/bin/env ruby

      require "#{node.gitlab.app_home}/config/boot"
      require "#{node.gitlab.app_home}/config/application"
      Rails.env = 'production'
      Rails.application.require_environment!

      unless ::User.where(email: "#{new_gitlab_user.email}")[0]
        user = ::User.new(
          name:     "#{new_gitlab_user.name}",
          email:    "#{new_gitlab_user.email}",
          password: "#{new_gitlab_user.password}"
        )
        user.admin = #{new_gitlab_user.admin}
        user.save!

        if #{new_gitlab_user.ssh_key ? "true" : "false"}
          @key = user.keys.new(title: 'Added by Chef', key: "#{new_gitlab_user.ssh_key}")
          @key.save!
        end
      end
    CODE
  end

  execute add_gitlab_user_script_path.split('/')[-1] do
    cwd     node['gitlab']['app_home']
    command "bundle exec ruby #{add_gitlab_user_script_path}"
    user  node['gitlab']['user']
    group node['gitlab']['group']
  end
end

action :remove do
end
