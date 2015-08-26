require 'spec_helper_acceptance'

describe 'files and directories', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  describe file('/etc/zuul/zuul.conf') do
    it { should be_file }
    it { should contain('[gearman]') }
    it { should contain('server=127.0.0.1') }
    it { should contain('[gerrit]') }
    it { should contain('server=') }
    it { should contain('[zuul]') }
    it { should contain('layout_config=/etc/zuul/layout/layout.yaml') }
  end

  describe file('/etc/default/zuul') do
    it { should be_file }
  end

  describe file('/var/log/zuul') do
    it { should be_directory }
    it { should be_owned_by 'zuul'}
  end

  describe file('/var/lib/zuul/git') do
    it { should be_directory }
    it { should be_owned_by 'zuul'}
  end

  describe 'directories belonging to zuul user and group' do
    directories = [
      file('/var/lib/zuul'),
      file('/var/run/zuul-merger'),
      file('/var/lib/zuul/ssh'),
      file('/var/run/zuul'),
    ]

    directories.each do |dir|
      describe dir do
        it { should be_directory }
        it { should be_owned_by 'zuul'}
        it { should be_grouped_into 'zuul'}
      end
    end
  end

  describe 'public_html symlinks' do
    symlinkies = {
      file('/var/lib/zuul/www/images') => '/opt/zuul/etc/status/public_html/images',
      file('/var/lib/zuul/www/index.html') => '/opt/zuul/etc/status/public_html/index.html',
      file('/var/lib/zuul/www/jquery.zuul.js') => '/opt/zuul/etc/status/public_html/jquery.zuul.js',
      file('/var/lib/zuul/www/styles') => '/opt/zuul/etc/status/public_html/styles',
      file('/var/lib/zuul/www/zuul.app.js') => '/opt/zuul/etc/status/public_html/zuul.app.js',
      file('/var/lib/zuul/www/lib/jquery.graphite.js') => '/opt/graphitejs/jquery.graphite.js',
      file('/var/lib/zuul/www/lib/bootstrap') => '/opt/twitter-bootstrap/dist',
    }

    symlinkies.each do |link, destination|
      describe link do
        it { should be_symlink }
        it { should be_linked_to destination }
      end
    end
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
