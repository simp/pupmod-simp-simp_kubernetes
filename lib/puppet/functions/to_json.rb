# Take a data structure and output it as JSON
#
# @example how to output JSON
#   # output json to a file
#     file { '/tmp/my.json':
#       ensure  => file,
#       content => to_json($myhash),
#     }
#
# From https://github.com/puppetlabs/puppetlabs-stdlib/blob/4.20.0/lib/puppet/functions/to_json.rb
# TODO Remove when stdlib is upgraded to 4.20.0 or newer
#
require 'json'

Puppet::Functions.create_function(:to_json) do
  dispatch :to_json do
    param 'Any', :data
  end

  def to_json(data)
    data.to_json
  end
end
