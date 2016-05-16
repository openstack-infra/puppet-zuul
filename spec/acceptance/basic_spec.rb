require 'spec_helper_acceptance'

describe 'puppet-zuul module', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def preconditions_puppet_module
    module_path = File.join(pp_path, 'preconditions.pp')
    File.read(module_path)
  end

  def post_conditions_puppet_module
    module_path = File.join(pp_path, 'postconditions.pp')
    File.read(module_path)
  end

  def default_puppet_module
    module_path = File.join(pp_path, 'default.pp')
    File.read(module_path)
  end

  before(:all) do
    apply_manifest(preconditions_puppet_module, catch_failures: true)
  end

  it 'should work with no errors' do
    apply_manifest(default_puppet_module, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(default_puppet_module, catch_changes: true)
  end

  it 'should enable zuul server and zuul merger services' do
    apply_manifest(post_conditions_puppet_module, catch_failures: true)
  end

  describe 'required users' do
    describe user('zuul') do
      it { should exist }
      it { should belong_to_group 'zuul' }
      it { should have_home_directory '/home/zuul' }
      it { should have_login_shell '/bin/bash' }
    end
  end

  describe 'required operating system packages' do
    packages = [
      package('git'),
      package('build-essential'),
      package('python-lxml'),
      package('python-yaml'),
      package('python-paramiko'),
      package('python-daemon'),
      package('yui-compressor'),
      package('python-paste'),
      package('python-webob')
    ]
    packages << package('apache2') if ['ubuntu', 'debian'].include?(os[:family])
    packages << package('httpd') if ['centos', 'redhat'].include?(os[:family])

    packages.each do |package|
      describe package do
        it { should be_installed }
      end
    end
  end

  describe 'required pip packages' do
    packages = [
      package('yappi'),
      package('zuul')
    ]

    packages.each do |package|
      describe package do
        it { should be_installed.by('pip') }
      end
    end
  end

  describe 'required files' do
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

  describe cron do
    it { should have_entry('7 4 * * * find /var/lib/zuul/git/ -maxdepth 3 -type d -name ".git" -exec git --git-dir="{}" pack-refs --all \;').with_user('zuul') }
  end

  describe 'required services' do
    describe port(80) do
      it { should be_listening }
    end

    describe command("curl http://localhost --location") do
      its(:stdout) { should contain('Zuul Status') }
    end

    describe port(443) do
      it { should be_listening }
    end

    describe command("curl https://localhost --insecure --location") do
      its(:stdout) { should contain('Zuul Status') }
    end

    describe port(4730) do
      it { should be_listening }
    end
  end
end
