require 'serverspec'

set :backend, :exec
set :path, '/sbin:/usr/local/sbin:$PATH'

describe 'default' do
  it 'dashing user and group' do
    expect(user 'dashing').to exist
    expect(group 'dashing').to exist
  end
  describe file('/usr/sbin/dashing-service') do
    it { should be_a_file }
    its(:content) { should include '# Setup JS' }
    its(:content) { should include '# Setup Ruby' }
  end
end
