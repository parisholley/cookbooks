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


# timing hack to avoid a race condition
# https://github.com/xforty/vagrant-drupal/issues/11
log "waiting for mysql to start..."
slumber = 0
until /running/.match(`service mysql status`)
    service "mysql" do
        action :start
        ignore_failure true
    end

    delay = 0.01
    sleep delay
    slumber += delay

    if slumber > 20 then
        log "stopped waiting for mysql"
        break
    end
end

include_recipe "mysql::server"


# hosts file
if File.exists?("#{node['vagrant']['directory']}/etc/hosts")
    execute "/etc/hosts" do
        command "cp #{node['vagrant']['directory']}/etc/hosts /etc/hosts"
        action :run
    end 
end


# set up the database
execute "create-database" do
    command "mysql -u root -p#{node['mysql']['server_root_password']} -e \"create database if not exists #{node['mysql']['database']}\""
    action :run
end

dumpfile = "dump.sql"
if ENV.key?('DBVERSION') && ENV['DBVERSION']
    dumpfile = "dump.v#{ENV['DBVERSION']}.sql"
end

log "using dumpfile: #{dumpfile}"

if File.exists?("#{node['vagrant']['directory']}/#{dumpfile}")
    execute "create-tables" do
        command "mysql -u root -p#{node['mysql']['server_root_password']} #{node['mysql']['database']} < #{node['vagrant']['directory']}/#{dumpfile}"
    end 
end


# configure apache
execute "disable-default-site" do
    command "sudo a2dissite default"
    notifies :reload, resources(:service => "apache2"), :delayed
end

web_app "php-app" do
    template "php-app.conf.erb"
    notifies :reload, resources(:service => "apache2"), :delayed
end