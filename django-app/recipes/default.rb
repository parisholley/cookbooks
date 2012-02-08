require_recipe "apt"
require_recipe "apache2"
require_recipe "apache2::mod_python"

require_recipe "python"

require_recipe "mysql::server"

execute "install-django" do
	command "pip install django"
	notifies :reload, resources(:service => "apache2"), :delayed
end

execute "install-mysql-python" do
	command "pip install mysql-python"
	notifies :reload, resources(:service => "apache2"), :delayed
end

execute "create-database" do
	command "mysql -uroot -p#{node['mysql']['server_root_password']} -e \"create database django\""
	action :run    
end

execute "create-tables" do
	command "cd #{node['vagrant']['directory']}/www/; python #{node['vagrant']['directory']}/www/manage.py syncdb --noinput"
end

execute "disable-default-site" do
	command "sudo a2dissite default"
	notifies :reload, resources(:service => "apache2"), :delayed
end

web_app "django-app" do
	template "django-app.conf.erb"
	notifies :reload, resources(:service => "apache2"), :delayed
end
