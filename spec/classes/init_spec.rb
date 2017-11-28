require 'simp_kubernetes'

describe 'simp_kubernetes' do

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          facts = os_facts
          facts
        end

        context 'simp_kubernetes class without any parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('docker').with(
            use_upstream_package_source: false,
          ) }
        end
      end
    end
  end
end
