require 'spec_helper_acceptance'

describe 'files and directories' do
  describe file('/etc/zuul/zuul.conf') do
    it { should be_file }
    it { should contain('[gearman]') }
    it { should contain('server=127.0.0.1') }
    it { should contain('[gerrit]') }
    it { should contain('server=') }
    it { should contain('[zuul]') }
    it { should contain('layout_config=/etc/zuul/layout/layout.yaml') }
  end

  describe file('/var/lib/zuul/ssh/id_rsa') do
    it { should be_file }
    it { should contain('-----BEGIN RSA PRIVATE KEY-----') }
  end

  describe file('/home/zuul/.ssh/known_hosts') do
    it { should be_file }
    it { should contain('known_hosts_content') }
  end
end
