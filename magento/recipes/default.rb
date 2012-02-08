require_recipe "apt"
require_recipe "apache2"

require_recipe "php::module_apc"
require_recipe "php::module_mysql"
require_recipe "php::module_curl"
require_recipe "php::module_gd"
require_recipe "php::module_mcrypt"

require_recipe "mysql::server"

execute "disable-default-site" do
	command "sudo a2dissite default"
	notifies :reload, resources(:service => "apache2"), :delayed
end

web_app "magento" do
	template "magento.conf.erb"
	notifies :reload, resources(:service => "apache2"), :delayed
end

execute "create-database" do
	command "mysql -uroot -p#{node['mysql']['server_root_password']} -e \"create database magento\""
	action :run	
end
