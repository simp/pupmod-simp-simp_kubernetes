# This test is to declare functionality of kubernetes on EL7 machines.
#
require 'spec_helper_acceptance'

test_name 'kubernetes using redhat provided packages'

describe 'kubernetes using redhat provided packages' do

  let(:manifest) { <<-EOS
      include 'simp_kubernetes'
    EOS
  }

end
