require 'spec_helper_acceptance'

describe 'operating system packages' do
  shared_examples "a required package is installed" do |packages|
    packages.each do |package|
      describe package(package) do
        it { should be_installed }
      end
    end
  end

  @installed_packages = ['git', 'gcc', 'python-lxml', 'python-yaml',
                         'python-paramiko', 'python-daemon', 'yui-compressor',
                         'python-paste', 'python-webob']
  @installed_packages << 'apache2' if ['ubuntu', 'debian'].include?(os[:family])
  @installed_packages << 'httpd' if ['centos', 'redhat'].include?(os[:family])

  it_behaves_like "a required package is installed", @installed_packages
end
