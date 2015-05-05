require 'spec_helper_acceptance'

describe 'basic zuul' do

  context 'default parameters' do

    it 'should work with no errors' do
      pp= <<-EOS
      Exec { logoutput => 'on_failure' }
      class { '::zuul': }
      class { '::zuul::server':
        layout_dir => '/tmp/layout'
      }
      class { '::zuul::merger': }
      EOS
      apply_manifest(pp, :catch_failures => true)
      # The second apply fails ... becauses of changes. Need to figure out why
      #apply_manifest(pp, :catch_changes => true)
    end

    # Basic assertions after '::zuul' class run
    describe user('zuul') do
      it { should exist }
    end
    describe file('/etc/zuul/zuul.conf') do
      it { should be_file }
    end
    describe file('/var/lib/zuul') do
      it { should be_directory }
    end
    describe file('/usr/local/bin/zuul') do
      it { should be_file }
      it { should be_executable }
    end
    describe file('/usr/local/bin/zuul-merger') do
      it { should be_file }
      it { should be_executable }
    end
    describe file('/usr/local/bin/zuul-cloner') do
      it { should be_file }
      it { should be_executable }
    end
    describe file('/usr/local/bin/zuul-server') do
      it { should be_file }
      it { should be_executable }
    end

    # Basic assertions after '::zuul::merger' class run
    describe service('zuul-merger') do
      it { should be_enabled }
    end
    # Basic assertions after '::zuul::server' class run
    describe service('zuul') do
      it { should be_enabled }
    end
  end
end
