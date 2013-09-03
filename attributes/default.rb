default["dashing"]["version"] = ""
default["dashing"]["user"] = "dashing"
default["dashing"]["group"] = "dashing"

default["dashing"]["ruby_env"] = ""
default["dashing"]["js_env"] = ""
default["dashing"]["dashing_exec"] = "dashing"

if node["platform"] == "ubuntu"
    default["dashing"]["service_type"] = "upstart"
else
    default["dashing"]["service_type"] = "init.d"
end
