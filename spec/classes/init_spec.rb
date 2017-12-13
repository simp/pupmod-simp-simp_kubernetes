require 'spec_helper'
require 'json'

describe 'simp_kubernetes' do

  shared_examples_for 'flannel' do
    it { is_expected.to contain_class('simp_kubernetes::flannel') }
    it { is_expected.to contain_package('flannel').with_ensure('installed') }
    it { is_expected.to contain_service('flanneld').with_ensure('running') }
    it { is_expected.to contain_file('/etc/sysconfig/flanneld').with(
      ensure: 'file',
      content: File.read('spec/expected/etc/sysconfig/flanneld.txt')
    ) }
  end

  shared_examples_for 'common configuration' do
    it { is_expected.to contain_class('simp_kubernetes::common_config') }
    it { is_expected.to contain_package('kubernetes').with_ensure('installed') }
    it { is_expected.to contain_file('/etc/kubernetes/config').with(
      ensure: 'file',
      content: File.read('spec/expected/etc/kubernetes/config.txt')
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
          context 'with minimal parameters' do
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
              content: File.read('spec/expected/etc/kubernetes/proxy.txt')
            ) }
            it { is_expected.to contain_class('simp_kubernetes::node::kubelet') }
            it { is_expected.to contain_service('kubelet').with_ensure('running') }
            it { is_expected.to contain_file('/etc/kubernetes/kubelet').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/kubernetes/kubelet.txt')
            ) }
          end

          context 'over https' do
            let(:params) {{
              etcd_peers: ['etcd01.test','etcd02.test','etcd03.test'],
              kube_masters: ['kube01.test','kube02.test'],
              use_simp_certs: true,
              etcd_peer_protocol: 'https',
              etcd_client_protocol: 'https',
              kubelet_protocol: 'https',
              kube_api_protocol: 'https',
              kube_api_port: 6443
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_pki__copy('simp_kubernetes').with_group('kube') }
            it { is_expected.to contain_pki__copy('simp_kubernetes-etcd').with_group('kube') }
            it { is_expected.to contain_file('/etc/sysconfig/flanneld').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/sysconfig/flanneld-tls.txt')
            ) }
            it { is_expected.to contain_file('/etc/kubernetes/config').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/kubernetes/config-tls.txt')
            ) }
            it { is_expected.to contain_file('/etc/kubernetes/kubelet').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/kubernetes/kubelet-tls.txt')
            ) }
          end
        end

        context 'on a master' do
          context 'with minimal parameters' do
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
              content: File.read('spec/expected/etc/kubernetes/apiserver.txt')
            ) }
            it { is_expected.to contain_class('simp_kubernetes::master::scheduler') }
            it { is_expected.to contain_service('kube-scheduler').with_ensure('running') }
            it { is_expected.to contain_file('/etc/kubernetes/scheduler').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/kubernetes/scheduler.txt')
            ) }
            it { is_expected.to contain_class('simp_kubernetes::master::controller_manager') }
            it { is_expected.to contain_service('kube-controller-manager').with_ensure('running') }
            it { is_expected.to contain_file('/etc/kubernetes/controller-manager').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/kubernetes/controller-manager.txt')
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
              peers: 'http://etcd01.test:2379,http://etcd02.test:2379,http://etcd03.test:2379',
            ) }
          end

          context 'over https' do
            let(:params) {{
              is_master: true,
              etcd_peers: ['etcd01.test','etcd02.test','etcd03.test'],
              kube_masters: ['kube01.test','kube02.test'],
              use_simp_certs: true,
              kube_api_port: 6443,
              etcd_peer_protocol: 'https',
              etcd_client_protocol: 'https',
              kubelet_protocol: 'https',
              kube_api_protocol: 'https',
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_pki__copy('simp_kubernetes').with_group('kube') }
            it { is_expected.to contain_pki__copy('simp_kubernetes-etcd').with_group('etcd') }
            it { is_expected.to contain_class('etcd').with(
              etcd_name: 'etcd01.test',
              peer_client_cert_auth: true,
              client_cert_auth: true,
              peer_cert_file: '/etc/pki/simp_apps/simp_kubernetes-etcd/x509/private/etcd01.test.pem',
              peer_key_file: '/etc/pki/simp_apps/simp_kubernetes-etcd/x509/private/etcd01.test.pem',
              peer_trusted_ca_file: '/etc/pki/simp_apps/simp_kubernetes-etcd/x509/cacerts/cacerts.pem',
              cert_file: '/etc/pki/simp_apps/simp_kubernetes-etcd/x509/private/etcd01.test.pem',
              key_file: '/etc/pki/simp_apps/simp_kubernetes-etcd/x509/private/etcd01.test.pem',
              trusted_ca_file: '/etc/pki/simp_apps/simp_kubernetes-etcd/x509/cacerts/cacerts.pem',
            ) }
            it { is_expected.to contain_etcd_key('/kube-simp/network/config').with(
              value: JSON.load(File.read('spec/expected/network_config.json')).to_json,
              peers: 'https://etcd01.test:2379,https://etcd02.test:2379,https://etcd03.test:2379',
              key_file: '/etc/pki/simp_apps/simp_kubernetes-etcd/x509/private/etcd01.test.pem',
              cert_file: '/etc/pki/simp_apps/simp_kubernetes-etcd/x509/private/etcd01.test.pem',
              ca_file: '/etc/pki/simp_apps/simp_kubernetes-etcd/x509/cacerts/cacerts.pem',
            ) }
            it { is_expected.to contain_file('/etc/sysconfig/flanneld').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/sysconfig/flanneld-tls.txt')
            ) }
            it { is_expected.to contain_file('/etc/kubernetes/config').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/kubernetes/config-tls.txt')
            ) }
            it { is_expected.to contain_file('/etc/kubernetes/apiserver').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/kubernetes/apiserver-tls.txt')
            ) }
            it { is_expected.to contain_file('/etc/kubernetes/controller-manager').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/kubernetes/controller-manager-tls.txt')
            ) }
            it { is_expected.to contain_file('/etc/kubernetes/scheduler').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/kubernetes/scheduler-tls.txt')
            ) }
          end

          context 'with extra api args' do
            let(:params) {{
              is_master: true,
              etcd_peers: ['etcd01.test','etcd02.test','etcd03.test'],
              kube_masters: ['kube01.test','kube02.test'],
              use_simp_certs: true,
              kube_api_port: 6443,
              etcd_peer_protocol: 'https',
              etcd_client_protocol: 'https',
              kubelet_protocol: 'https',
              kube_api_protocol: 'https',
              master_api_args: { 'log-flush-frequency' => 15 },
              api_args: { 'max-pods' => 10 },
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_file('/etc/kubernetes/config').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/kubernetes/config-extra.txt')
            ) }
            it { is_expected.to contain_file('/etc/kubernetes/apiserver').with(
              ensure: 'file',
              content: File.read('spec/expected/etc/kubernetes/apiserver-extra.txt')
            ) }
          end
        end
      end
    end
  end
end
