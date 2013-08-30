# LWRP to turn a dashboard into a service.
#
# Example:
#
#     dashing_dashboard "/opt/my_dashboard" do
#         port 8080
#     end
#
# This will also create a chef service resource called "dashing-my_dashboard" when can be notified
# if a restart is required.
#

actions [:create, :delete, :restart]

default_action :create

# Full path to the directory containing the dashboard.  This directory should already exist.
attribute :path,         :kind_of => String,  :name_attribute => true

# Port to launch the dashboard on
attribute :port,         :kind_of => Integer, :default => 8080

# Override the service type.  Can be any value supported by node["dashing"]["service_type"]
attribute :service_type, :kind_of => String,  :default => nil
