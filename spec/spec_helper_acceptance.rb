require 'beaker-rspec'
require 'tmpdir'
require 'yaml'
require 'simp/beaker_helpers'
include Simp::BeakerHelpers

unless ENV['BEAKER_provision'] == 'no'
 hosts.each do |host|
   # Install Puppet
   if host.is_pe?
     install_pe
   else
     install_puppet
   end
 end
end


def certs(host, ip)
  keypair = OpenSSL::PKey::RSA.new( 4096 )

  req            = OpenSSL::X509::Request.new
  req.version    = 0
  req.subject    = OpenSSL::X509::Name.parse(
      "CN=#{host}/O=Hosts/OU=Fake Org/C=ZZ"
  )
  req.public_key = keypair.public_key
  req.sign( keypair, OpenSSL::Digest::SHA1.new )

  cert            = OpenSSL::X509::Certificate.new
  cert.version    = 2
  cert.serial     = rand( 999999 )
  cert.not_before = Time.new
  cert.not_after  = cert.not_before + (60 * 60 * 24 * 365)
  cert.public_key = req.public_key
  cert.subject    = req.subject
  cert.issuer     = ca.subject

  ef = OpenSSL::X509::ExtensionFactory.new
  ef.subject_certificate = cert
  ef.issuer_certificate  = ca

  cert.extensions = [
      ef.create_extension( 'basicConstraints', 'CA:FALSE', true ),
      ef.create_extension( 'extendedKeyUsage', 'serverAuth', false ),
      ef.create_extension( 'subjectKeyIdentifier', 'hash' ),
      ef.create_extension( 'subjectAltName', "IP:#{ip}" ),
      ef.create_extension( 'authorityKeyIdentifier', 'keyid:always,issuer:always' ),
      ef.create_extension( 'keyUsage',
          %w(nonRepudiation digitalSignature
          keyEncipherment dataEncipherment).join(","),
          true
      )
  ]
  cert.sign( ca_key, OpenSSL::Digest::SHA1.new )
end


RSpec.configure do |c|
  # ensure that environment OS is ready on each host
  fix_errata_on hosts

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    begin
      # Install modules and dependencies from spec/fixtures/modules
      copy_fixture_modules_to( hosts )

      # Generate and install PKI certificates on each SUT
      Dir.mktmpdir do |cert_dir|
        run_fake_pki_ca_on( default, hosts, cert_dir )
        hosts.each do |sut|
          copy_pki_to( sut, cert_dir, '/etc/pki/simp-testing' )
          on( sut, 'chown -R root:root /etc/pki/simp-testing')
          on( sut, 'chmod -R ugo=rX /etc/pki/simp-testing')
        end
      end
    rescue StandardError, ScriptError => e
      if ENV['PRY']
        require 'pry'; binding.pry
      else
        raise e
      end
    end
  end
end
