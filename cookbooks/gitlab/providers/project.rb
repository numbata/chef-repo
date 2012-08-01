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

action :add do
  Chef::Log.info "Adding project '#{new_resource.name}' to Gitlab"

  # Hack around in Gitlab
  new_project = @new_resource
  add_gitlab_project_script_path = "#{node.gitlab.app_home}/add_gitlab_project_#{new_project.name.downcase.gsub(/\s/, '_')}.rb"
  file add_gitlab_project_script_path do
    owner node['gitlab']['user']
    group node['gitlab']['group']
    mode  0755
    content <<-CODE
      require "#{node.gitlab.app_home}/config/boot"
      require "#{node.gitlab.app_home}/config/application"
      Rails.env = 'production'
      Rails.application.require_environment!

      unless ::Project.where(name: "#{new_project.name}")
        project_owner = ::User.where(email: "#{new_project.owner_email}")[0]
        admin_project = ::Project.new(name: "#{new_project.name}", path: "#{new_project.path}", code: "#{new_project.code}", description: "Added by Chef", owner: project_owner)
        admin_project.save!


        team_members_emails = #{new_project.team_members.map { |gitlab_user| gitlab_user.email }.to_s}
        team_members_ids = team_members_emails.map { |user_email| ::User.where(email: user_email)[0].id }

        team_members_ids.each do |user_id|
          puts "Add user with id=#\{user_id} to project #\{admin_project.name}"
          users_project = ::UsersProject.new(
            :user_id => user_id,
            :project_access => ::UsersProject::MASTER
          )
          users_project.project = admin_project
          users_project.save!
        end
      end
    CODE
  end

  execute add_gitlab_project_script_path.split('/')[-1] do
    cwd     node['gitlab']['app_home']
    command "bundle exec ruby #{add_gitlab_project_script_path}"
    user  node['gitlab']['user']
    group node['gitlab']['group']
  end
end
