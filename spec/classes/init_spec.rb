require 'spec_helper'
describe 'zuul' do

  context 'with defaults for all parameters' do
    it { should contain_class('zuul') }
  end
end
