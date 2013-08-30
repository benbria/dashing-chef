dashing Cookbook
================

Installs [Dashing](http://shopify.github.io/dashing/) and configures dashboards to run as services.

Dashing is installed via rbenv, so as not to interfere with other services which may require other
versions of Ruby.

Tested with Ubuntu 12.04.

License
-------
MIT License

Requirements
------------
#### packages
- `[rbenv](https://github.com/RiotGames/rbenv-cookbook)` - Used to install Ruby

Attributes
----------
#### dashing::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>["dashing"]["ruby_version"]</tt></td>
    <td>String</td>
    <td>The version of ruby to use/install</td>
    <td><tt>1.9.3-p385</tt></td>
  </tr>
  <tr>
    <td><tt>["dashing"]["user"]</tt></td>
    <td>String</td>
    <td>The user to run dashboards as</td>
    <td><tt>dashing</tt></td>
  </tr>
  <tr>
    <td><tt>["dashing"]["group"]</tt></td>
    <td>String</td>
    <td>The group to run dashboards as</td>
    <td><tt>dashing</tt></td>
  </tr>
  <tr>
    <td><tt>["dashing"]["service_type"]</tt></td>
    <td>String</td>
    <td>The service type to install dashboards as</td>
    <td><tt>"upstart" on ubuntu, "init.d" otherwise</tt></td>
  </tr>
</table>

LWRPs
-----

See "Usage" below for examples.

#### dashing_dashboard

Actions:

* `:nothing` - Standard do-nothing action.
* `:create` - Creates a service which runs the given dashboard automatically at system startup.
  This will also run `bundle` in the dashboard's directory.  If the dashboard already is configured
  as a service, `:create` will *not* restart it.
* `:restart` - Like `:create`, but this will always restart the service - handy if you're going to
  use `notifies` on whatever resource you're using to deploy your dashboard.
* `:delete` - Stops and removes the service for a dashboard.  This won't actually delete the
  directory the dashboard is stored in.

Attributes:

* `path` - The path to the dashboard (if not specified, the name of the resource is used.)
* `port` - Optional - The port to run the `thin` webserver on.  Note that dashing has no security,
  so some sort of firewall is recommended.  Defaults to `8080`.
* `service_type` - Optional - Defaults to `node["dashing"]["service_type"]`, although you can use
  this if, for some crazy reason, you want some of your dashboards to be managed by upstart, and
  some by init.d.


Usage
-----
Including `dashing` in your node's `run_list` will install Ruby (via rbenv) and Dashing:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[dashing]"
  ]
}
```

This cookbook also provides the `dashing_dashboard` LWRP for setting up dashboards as system
services:

    # Install rbenv and dashing
    include_recipe 'dashing'

    # Fetch our dashboard from git
    git "/opt/dashing/my_dashboard" do
        repository "git://github.com/benbria/dashboard.git"
        reference "master"
        action :sync
    end

    # Configure the dashboard as a service.
    dashing_dashboard "/opt/dashing/my_dashboard" do
        action :restart
        port 9090
    end


Contributing
------------
Fork and pull request, please! :)

License and Authors
-------------------
Authors:
* [Jason Walton](mailto:jwalton@benbria.ca)
