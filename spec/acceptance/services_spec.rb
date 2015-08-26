require 'spec_helper_acceptance'

describe 'zuul services' do
  describe service('apache2'), :if => ['debian', 'ubuntu'].include?(os[:family]) do
    it { should be_enabled }
    it { should be_running }
  end

  describe service('httpd'), :if => ['centos', 'redhat'].include?(os[:family]) do
    it { should be_enabled }
    it { should be_running }
  end

  describe port(80) do
    it { should be_listening }
  end

  describe command("curl http://localhost:80 --insecure --location") do
    its(:stdout) { should contain('Zuul Status') }
  end

  describe port(443) do
    it { should be_listening }
  end

  describe command("curl https://localhost:443 --insecure --location") do
    its(:stdout) { should contain('Zuul Status') }
  end

  describe port(4730) do
    it { should be_listening }
  end
end
