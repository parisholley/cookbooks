require_recipe "apt"
require_recipe "apache2"
require_recipe "apache2::mod_rewrite"
require_recipe "apache2::mod_proxy"
require_recipe "apache2::mod_proxy_http"

require_recipe "php::module_apc"
require_recipe "php::module_mysql"
require_recipe "php::module_curl"
require_recipe "php::module_gd"
require_recipe "php::module_mcrypt"

require_recipe "mysql::server"


if File.exists?("#{node['vagrant']['directory']}/etc/hosts")
        execute "/etc/hosts" do
                command "cp #{node['vagrant']['directory']}/etc/hosts /etc/hosts"
                action :run    
        end 
end

execute "create-database" do
        command "mysql -uroot -p#{node['mysql']['server_root_password']} -e \"create database #{node['mysql']['database']}\""
        action :run    
end 
        
if File.exists?("#{node['vagrant']['directory']}/dump.sql")
        execute "create-tables" do
                command "mysql -uroot -p#{node['mysql']['server_root_password']} #{node['mysql']['database']} < #{node['vagrant']['directory']}/dump.sql"
        end 
end

execute "disable-default-site" do
        command "sudo a2dissite default"
        notifies :reload, resources(:service => "apache2"), :delayed
end

web_app "php-app" do
        template "php-app.conf.erb"
        notifies :reload, resources(:service => "apache2"), :delayed
end
