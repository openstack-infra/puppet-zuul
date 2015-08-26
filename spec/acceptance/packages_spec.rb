require 'spec_helper_acceptance'

describe 'operating system packages', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  packages = [
    package('git'),
    package('gcc'),
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

describe 'pip packages' do
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
