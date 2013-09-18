actions :install
default_action :install

attribute :name, :kind_of => String, :name_attribute => true
attribute :domain, :kind_of => String
attribute :root_directory, :kind_of => String
attribute :public_directory, :kind_of => String
attribute :log_directory, :kind_of => String
