# Turn a hash into a string with eash key prefixed
# with -- and connected to each value with =
#
# @example simp_kubernetes::hash_to_opts({'key' => 'value'})
#   returns `--key=value`
#
function simp_kubernetes::hash_to_opts(Hash[String,Variant[Array,String,Numeric,Boolean,Undef]] $h) {
  $b = $h.map |$key, $val| {
    case $val {
      Undef:         { "--${key}"                      }
      Array:         { "--${key}=\"${val.join(',')}\"" }
      /[[:blank:]]/: { "--${key}=\"${val}\""           }
      default:       { "--${key}=${val}"               }
    }
  }
  $b.join(' ')
}
