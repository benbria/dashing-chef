default["dashing"]["version"] = ""
default["dashing"]["user"] = "dashing"
default["dashing"]["group"] = "dashing"

default["dashing"]["ruby_env"] = ""
default["dashing"]["js_env"] = ""
default["dashing"]["dashing_exec"] = "dashing"

if node['platform'] == 'ubuntu'
  if node['platform_version'].to_i < 12
    default['dashing']['service_type'] = 'init.d'
  else
      default['dashing']['service_type'] = 'upstart'
  end
elsif node['platform'] == 'debian'
    if node['platform_version'].to_i < 8
        default['dashing']['service_type'] = 'upstart'
    else
        default['dashing']['service_type'] = 'systemd'
    end
else
    default['dashing']['service_type'] = 'init.d'
end

default['dashing']['init_source'] = case node['platform_family']
                                    when 'debian'
                                        'initd-dashboard.sh.erb'
                                    when 'rhel'
                                        'initd-rh-dashboard.sh.erb'
                                    end
