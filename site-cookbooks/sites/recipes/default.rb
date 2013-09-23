# Cookbook Name:: gnomiki.ru
# Recipe:: default
node['sites']['php'].each do |site|
  sites_php(site['name']) do
    action [:install]
    domain site['domain']
  end
end
