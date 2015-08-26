require 'spec_helper_acceptance'

describe 'users', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  describe user('zuul') do
    it { should exist }
    it { should belong_to_group 'zuul' }
    it { should have_home_directory '/home/zuul' }
    it { should have_login_shell '/bin/bash' }
  end
end
