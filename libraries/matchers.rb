if defined?(ChefSpec)
  def create_dashing_dashboard(name)
    ChefSpec::Matchers::ResourceMatcher.new(:dashing_dashboard, :create, name)
  end

  def delete_dashing_dashboard(name)
    ChefSpec::Matchers::ResourceMatcher.new(:dashing_dashboard, :delete, name)
  end

  def restart_dashing_dashboard(name)
    ChefSpec::Matchers::ResourceMatcher.new(:dashing_dashboard, :restart, name)
  end
end
