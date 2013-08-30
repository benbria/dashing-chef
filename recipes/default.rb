#
# Cookbook Name:: dashing
# Recipe:: default
#
# Copyright 2013, Benbria
#

# Rbenv, Ruby and Gem
include_recipe "rbenv::default"
include_recipe "rbenv::ruby_build"
rbenv_ruby node["dashing"]["ruby_version"]

rbenv_gem "bundler" do
  ruby_version node["dashing"]["ruby_version"]
end

# Install dashing
rbenv_gem "dashing" do
    ruby_version node["dashing"]["ruby_version"]
end

# Create user/group to run dashboards
group node["dashing"]["group"]
user node["dashing"]["user"] do
    group node["dashing"]["group"]
    system true
end