include_recipe "apt"
include_recipe "apache2"
include_recipe "apache2::mod_rewrite"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_http"

include_recipe "php::module_apc"
include_recipe "php::module_mysql"
include_recipe "php::module_curl"
include_recipe "php::module_gd"
include_recipe "php::module_mcrypt"

include_recipe "mysql::server"

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
