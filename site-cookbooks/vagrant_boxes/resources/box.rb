actions :install, :up
default_action :install

attribute :name, :kind_of => String, :name_attribute => true
attribute :source, :kind_of => String
