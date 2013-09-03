#
# Cookbook Name:: dashing
# Recipe:: default
#
# Copyright 2013, Benbria
#

script "Install dashing" do
    interpreter "bash"
    user "root"
    options = if (node["dashing"]["version"] == "") then "" else "--version '#{node["dashing"]["version"]}'" end
    code <<-EOH

    # Quit on error
    set -e

    #{node["dashing"]["ruby_env"]}

    if ! gem spec dashing > /dev/null 2>&1; then
        gem install #{options} dashing
    fi

    EOH
end

# TODO: Would be nice to restart the various services if this changes...  We could write
# the ruby and js environments into each startup script as comments, maybe?

# TODO: Would be nice to not have this file at all.  Everything ought to be self-contained in
# the service scripts.  The script is nice because it lets the ruby_env and js_env be a bit more
# free-form.

template "/usr/sbin/dashing-service" do
    cookbook "dashing"
    source "dashing-service.sh.erb"
    mode 0755
    owner "root"
    group "root"
end

# Create user/group to run dashboards
group node["dashing"]["group"]
user node["dashing"]["user"] do
    group node["dashing"]["group"]
    system true
end