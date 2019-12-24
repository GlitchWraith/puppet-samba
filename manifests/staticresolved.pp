# This Class it deploy additional config for a samba ad dc
# 
# Create a static Hosts file with fqdn 
# Create a Static /etc/resolved.conf only required when systemd resolved caused problems
# deploy the kerberos file that samba creates
#
# Most of this it to get the standard samba::dc to work on 18.04
# Default is set to false to not cause issues with configs


class samba::staticresolved(
  $hosts                  = false,
  $staticresolved         = false,
  $kerberos               = false,
  $sambakrbgenerated      = '/var/lib/samba/private/krb5.conf',
  $additionalnameservers    = [],
)inherits samba::params{
  #include samba::dc
  require samba::dc

  if $hosts {
    exec{ 'add fqdn to /etc/hosts':
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      command => "/bin/sed -i \'1s;^;${ip} ${$facts['fqdn']} ${$facts['hostname']}\\n;\' /etc/hosts",
      onlyif  => "grep -c ${$facts['fqdn']} /etc/hosts",
    }
  }
}
