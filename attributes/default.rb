default["dashing"]["ruby_version"] = "1.9.3-p385"
default["dashing"]["user"] = "dashing"
default["dashing"]["group"] = "dashing"

if node["platform"] == "ubuntu"
    default["dashing"]["service_type"] = "upstart"
else
    default["dashing"]["service_type"] = "init.d"
end
