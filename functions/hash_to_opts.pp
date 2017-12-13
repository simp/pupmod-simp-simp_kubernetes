# Turn a hash into a string with eash key prefixed
# with '--' and connected to each value with '='
#
# @example simp_kubernetes::hash_to_opts({'key' => 'value'})
#   returns `--key=value`
# @example simp_kubernetes::hash_to_opts({'key' => ['lo',7,false]})
#   returns `--key="lo,7,false"`
# @example simp_kubernetes::hash_to_opts({'key' => Undef })
#   returns `--key`
#
# @param h Input hash, with Strings as keys and either a String, Array,
#   Numeric, Boolean, or Undef as a value.
#
# @return [String]
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
