require 'spec_helper_acceptance'

describe cron('zuul_repack') do
  it { should have_entry('7 4 * * * find /var/lib/zuul/git/ -maxdepth 3 -type d -name ".git" -exec git --git-dir="{}" pack-refs --all \\\;').with_user('zuul') }
end
