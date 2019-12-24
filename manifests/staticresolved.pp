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
)inherits ::samba::params{

  #include samba::dc
  require samba::dc

  if $kerberos {
    # This can probbly be exstended to debain but not tested
      if $facts['os']['name'] == 'Ubuntu' {
        package{ 'kerberoskdc':
          ensure  => 'installed',
          name    => $::samba::params::packagekrb5,
          #before  => [ Exec['provisionAD'], ],#Exec['CleanService'] ],
        }
        package{ 'kerberoskdc-pam':
          ensure  => 'installed',
          name    => $::samba::params::packagekrb5pam,
          #before  => [ Exec['provisionAD'],], # Exec['CleanService'] ],
        }
        file{'kerberosConfig':
          path    => $::samba::params::krbconffile,
          source  =>"file://${::samba::params::sambakrbgenerated}",
          require  =>  [ Package['kerberoskdc-pam'], Package['kerberoskdc'],], #  Exec['provisionAD'],
        }    
      }
  }

  if $hosts {
    exec{ 'add fqdn to /etc/hosts':
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      command => "/bin/sed -i \'1s;^;${ip} ${$facts['fqdn']} ${$facts['hostname']}\\n;\' /etc/hosts",
      onlyif  => "grep -c ${$facts['fqdn']} /etc/hosts",
    }
  }

  if $staticresolved {
    exec{ 'unlink':
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      command     => 'unlink /etc/resolv.conf',
      require     => [ Exec['provisionAD'], Package['PyYaml'],],
    }
    file {'/etc/resolve.conf':
        ensure  => present,
        mode    => '0644',
        content => template("${module_name}/resolv.conf.erb"),
        require => [ Exec['unlink'], Exec['stop systemd resolve'],],
    }
    exec{ 'stop systemd resolve':
      path      => '/bin:/sbin:/usr/bin:/usr/sbin',
      command   => '/bin/systemctl stop systemd-resolved; systemctl disable systemd-resolved',
      #require   => [ Exec['provisionAD'], File['SambaCreateHome'], Exec['unlink'], ],
      before    => [ File['/etc/resolve.conf'], ],
    }
  }
}
