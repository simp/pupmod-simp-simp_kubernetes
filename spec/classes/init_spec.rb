require 'spec_helper'
require 'json'

describe 'simp_kubernetes' do

  shared_examples_for 'flannel' do
    it { is_expected.to contain_class('simp_kubernetes::flannel') }
    it { is_expected.to contain_package('flannel').with_ensure('installed') }
    it { is_expected.to contain_service('flanneld').with_ensure('running') }
    it { is_expected.to contain_file('/etc/sysconfig/flanneld').with(
      ensure: 'file',
      content: File.read('spec/expected/flanneld.txt')
    ) }
  end

  shared_examples_for 'common configuration' do
    it { is_expected.to contain_class('simp_kubernetes::common_config') }
    it { is_expected.to contain_package('kubernetes').with_ensure('installed') }
    it { is_expected.to contain_file('/etc/kubernetes/config').with(
      ensure: 'file',
      content: File.read('spec/expected/config.txt')
    ) }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          facts = os_facts
          facts['fqdn'] = 'etcd01.test'
          facts
        end

        context 'without any parameters' do
          it { is_expected.to compile.and_raise_error(/expects a value for parameter 'etcd_peers'/) }
          it { is_expected.to compile.and_raise_error(/expects a value for parameter 'kube_masters'/) }
        end

        context 'on a node' do
          let(:params) {{
            etcd_peers: ['etcd01.test','etcd02.test','etcd03.test'],
            kube_masters: ['kube01.test','kube02.test'],
          }}
          it { is_expected.to compile.with_all_deps }
          it_behaves_like 'flannel'
          it_behaves_like 'common configuration'
          it { is_expected.to contain_class('simp_kubernetes') }
          it { is_expected.to contain_class('simp_kubernetes::common_config') }
          it { is_expected.to contain_class('simp_kubernetes::node') }
          it { is_expected.to contain_class('simp_kubernetes::node::proxy') }
          it { is_expected.to contain_service('kubelet').with_ensure('running') }
          it { is_expected.to contain_file('/etc/kubernetes/proxy').with(
            ensure: 'file',
            content: File.read('spec/expected/proxy.txt')
          ) }
          it { is_expected.to contain_class('simp_kubernetes::node::kubelet') }
          it { is_expected.to contain_service('kubelet').with_ensure('running') }
          it { is_expected.to contain_file('/etc/kubernetes/kubelet').with(
            ensure: 'file',
            content: File.read('spec/expected/kubelet.txt')
          ) }
        end

        context 'on a master' do
          let(:params) {{
            is_master: true,
            etcd_peers: ['etcd01.test','etcd02.test','etcd03.test'],
            kube_masters: ['kube01.test','kube02.test'],
          }}
          it { is_expected.to compile.with_all_deps }
          it_behaves_like 'flannel'
          it_behaves_like 'common configuration'
          it { is_expected.to contain_class('simp_kubernetes') }
          it { is_expected.to contain_class('simp_kubernetes::common_config') }
          it { is_expected.to contain_class('simp_kubernetes::master') }
          it { is_expected.to contain_class('simp_kubernetes::master::apiserver') }
          it { is_expected.to contain_service('kube-apiserver').with_ensure('running') }
          it { is_expected.to contain_file('/etc/kubernetes/apiserver').with(
            ensure: 'file',
            content: File.read('spec/expected/apiserver.txt')
          ) }
          it { is_expected.to contain_class('simp_kubernetes::master::scheduler') }
          it { is_expected.to contain_service('kube-scheduler').with_ensure('running') }
          it { is_expected.to contain_file('/etc/kubernetes/scheduler').with(
            ensure: 'file',
            content: File.read('spec/expected/scheduler.txt')
          ) }
          it { is_expected.to contain_class('simp_kubernetes::master::controller_manager') }
          it { is_expected.to contain_service('kube-controller-manager').with_ensure('running') }
          it { is_expected.to contain_file('/etc/kubernetes/controller-manager').with(
            ensure: 'file',
            content: File.read('spec/expected/controller-manager.txt')
          ) }
          it { is_expected.to contain_class('etcd').with(
            etcd_name:                   'etcd01.test',
            listen_client_urls:          'http://0.0.0.0:2379',
            advertise_client_urls:       'http://etcd01.test:2379,http://etcd02.test:2379,http://etcd03.test:2379',
            listen_peer_urls:            'http://0.0.0.0:2380',
            initial_advertise_peer_urls: 'http://0.0.0.0:2380',
            initial_cluster:             [ 'etcd01.test=http://0.0.0.0:2380',
                                           'etcd02.test=http://etcd02.test:2380',
                                           'etcd03.test=http://etcd03.test:2380'
                                         ],
          ) }
          it { is_expected.to contain_etcd_key('/kube-simp/network/config').with(
            value: JSON.load(File.read('spec/expected/network_config.json')).to_json,
            peers: 'http://127.0.0.1:2379'
          ) }
        end
      end
    end
  end
end
