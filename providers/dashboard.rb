require 'pathname'

def initialize(*args)
  super
  new_resource.service_type( (new_resource.service_type or node["dashing"]["service_type"]) )

end

def load_current_resource
    @current_resource = Chef::Resource::DashingDashboard.new(@new_resource.name)
    @current_resource.name(@new_resource.name)
    @current_resource.path(@new_resource.path)
    @current_resource.port(@new_resource.port)

    service_name = get_service_name()
    if ::File.exists?("/etc/init/#{service_name}.conf")
        service_type = "upstart"
    elsif ::File.exists?("/etc/init.d/#{service_name}")
        service_type = "init.d"
    else
        service_type = nil
    end
    @current_resource.service_type(service_type)
end

# Delete a dashboard.
action :delete do
    if current_resource.service_type == nil
        Chef::Log.warn("Service not installed - nothing to do.")
    else
        create_service(current_resource, :stop)
        delete_service_files(current_resource)
    end
end

# Create a dashboard
action :create do
    setup_dashboard(current_resource, new_resource)
end

# Create a dashboard and force a restart.
action :restart do
    # Stop the old service, if there is one.
    if current_resource.service_type != nil
        create_service(current_resource, :stop)
    end

    # Make sure the dashboard is setup and running
    setup_dashboard(current_resource, new_resource)

    # Force-restart the dashboard service.
    create_service(new_resource, :restart)
end

private

def setup_dashboard(current_resource, new_resource)
    # So that we can refer to these within the sub-run-context block.
    cached_new_resource = new_resource
    cached_current_resource = current_resource

    # Setup a sub-run-context.
    sub_run_context = @run_context.dup
    sub_run_context.resource_collection = Chef::ResourceCollection.new

    # Declare sub-resources within the sub-run-context. Since they are declared here,
    # they do not pollute the parent run-context.
    begin
        original_run_context, @run_context = @run_context, sub_run_context

        service_name = get_service_name()
        dashboard_exists = ::File.exists?(cached_new_resource.path)

        if !dashboard_exists
            Chef::Log.warn("Creating dashboard: #{get_dashboard_name()}")
        end

        if cached_current_resource.service_type != cached_new_resource.service_type
            # Need to stop the service before we remove the old service scripts.
            service_action = :stop
        else
            # Service will be notified if it needs to be started or restarted.
            service_action = :nothing
        end
        create_service(cached_new_resource, service_action)

        # Create the dashboard directory
        directory cached_new_resource.path do
            owner node["dashing"]["user"]
            group node["dashing"]["group"]
            mode "0755"
            recursive true
            action :create
        end

        # Set the ruby version for the dashboard directory
        file "#{cached_new_resource.path}/.ruby-version" do
            content node["dashing"]["ruby_version"]
            owner node["dashing"]["user"]
            group node["dashing"]["group"]
            mode "0544"
        end

        # Unpack the dashboard
        script "#{get_dashboard_name()} - Unpack dashboard" do
            interpreter "bash"
            user "root"
            cwd cached_new_resource.path
            code <<-EOH

            # Quit on error
            set -e

            echo "init"
            #{node["dashing"]["ruby_env"]}
            dashing new .

            EOH

            only_if {!dashboard_exists}
        end

        # Fix ownership of dashboard directory.
        script "#{get_dashboard_name()} - chown dashboard" do
            interpreter "bash"
            user "root"
            cwd cached_new_resource.path
            code <<-EOH
            chown -R "#{node["dashing"]["user"]}":"#{node["dashing"]["group"]}" .
            EOH
        end

        # TODO: Probably don't want to bundle the dashboard here.  Or, if new gems are installed,
        # restart the dashboard?  How would we detect this?
        script "#{get_dashboard_name()} - bundle" do
            interpreter "bash"
            user "root"
            cwd cached_new_resource.path
            code <<-EOH

            # Quit on error
            set -e

            #{node["dashing"]["ruby_env"]}
            bundle

            EOH

        end
        # Create startup scripts, and delete old scripts if the service type has changed.
        create_service_files(cached_current_resource, cached_new_resource)

    ensure
        @run_context = original_run_context
    end

    # Converge the sub-run-context inside the provider action.
    # Make sure to mark the resource as updated-by-last-action if any sub-run-context
    # resources were updated (any actual actions taken against the system) during the
    # sub-run-context convergence.
    begin
        Chef::Runner.new(sub_run_context).converge
    ensure
        if sub_run_context.resource_collection.any?(&:updated?)
            new_resource.updated_by_last_action(true)
        end
    end

end

# Create a chef `service` for the dashboard.
def create_service(resource, actions)
    service_name = get_service_name()

    case resource.service_type
    when "upstart"
        service service_name do
            provider Chef::Provider::Service::Upstart
            supports :status => true, :restart => true, :reload => true
            action actions
        end
    when "init.d"
        service service_name do
            supports :status => true, :restart => true, :reload => true
            action actions
        end
    else
        raise "dashing: Unknown service_type '#{resource.service_type}'"
    end
end

# Create startup scripts, and delete old scripts if the service type has changed.
def create_service_files(current_resource, new_resource)
    service_name = get_service_name(new_resource)

    template_variables = ({
        "dashboard_name" => get_dashboard_name(new_resource),
        "dashboard_path" => new_resource.path,
        "dashboard_port" => new_resource.port,
        "service_name" => service_name,
        "ruby_version" => node["dashing"]["ruby_version"]
    })

    # If the resource's service_type is changing, then delete the old script.
    if get_service_script_name(current_resource) != nil
        file get_service_script_name(current_resource) do
            action :delete
            only_if {current_resource.service_type != new_resource.service_type}
        end
    end

    # Create the new startup script.
    case new_resource.service_type
    when "upstart"
        template "/etc/init/#{service_name}.conf" do
            cookbook "dashing"
            source "upstart-dashboard.conf.erb"
            mode 0644
            owner "root"
            group "root"
            variables template_variables
            notifies :enable,  "service[#{service_name}]"
            notifies :restart, "service[#{service_name}]"
        end

    when "init.d"
        template "/etc/init.d/#{service_name}" do
            cookbook "dashing"
            source "initd-dashboard.sh.erb"
            mode 0755
            owner "root"
            group "root"
            variables template_variables
            notifies :enable,  "service[#{service_name}]"
            notifies :restart, "service[#{service_name}]"
        end

    end
end

# Delete files associated with a dashboard service
def delete_service_files(resource)
    if get_service_script_name != nil
        file get_service_script_name(resource) do
            action :delete
        end
    end
end

# Return the name of the script that starts the service for a given dashboard.
def get_service_script_name(resource=nil)
    if resource == nil then resource = @new_resource end

    answer = nil
    case resource.service_type
    when "upstart"
        answer = "/etc/init/#{get_service_name(resource)}.conf"
    when "init.d"
        answer = "/etc/init.d/#{get_service_name(resource)}"
    end
    return answer
end


def get_dashboard_name(resource=nil)
    if resource == nil then resource = @new_resource end
    return Pathname.new(resource.path).basename
end

def get_service_name(resource=nil)
    if resource == nil then resource = @new_resource end
    return "dashing-#{get_dashboard_name(resource)}"
end