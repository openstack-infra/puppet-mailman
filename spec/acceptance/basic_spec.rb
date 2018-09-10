require 'puppet-openstack_infra_spec_helper/spec_helper_acceptance'

describe 'basic mailman', :if => ['debian', 'ubuntu'].include?(os[:family]) do

  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def puppet_manifest
    module_path = File.join(pp_path, 'default.pp')
    File.read(module_path)
  end

  it 'should work with no errors' do
    apply_manifest(puppet_manifest, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(puppet_manifest, catch_changes: true)
  end

  describe command("curl http://localhost/cgi-bin/mailman/listinfo") do
    its(:stdout) { should contain('Mailing Lists') }
  end

  expected_vhost = <<EOF
<VirtualHost *:80>
	ServerName lists.openstack.org

	ErrorLog \${APACHE_LOG_DIR}/lists.openstack.org-error.log

	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn

	CustomLog \${APACHE_LOG_DIR}/lists.openstack.org-access.log combined

	DocumentRoot /var/www

RewriteEngine on
RewriteRule ^/$ /cgi-bin/mailman/listinfo [R]

# We can find mailman here:
ScriptAlias /cgi-bin/mailman/ /usr/lib/cgi-bin/mailman/
# And the public archives:
Alias /pipermail/ /var/lib/mailman/archives/public/
# Logos:
Alias /images/mailman/ /usr/share/images/mailman/

# Use this if you don't want the "cgi-bin" component in your URL:
# In case you want to access mailman through a shorter URL you should enable
# this:
#ScriptAlias /mailman/ /usr/lib/cgi-bin/mailman/
# In this case you need to set the DEFAULT_URL_PATTERN in
# /etc/mailman/mm_cfg.py to http://%s/mailman/ for the cookie
# authentication code to work.  Note that you need to change the base
# URL for all the already-created lists as well.

<Directory /usr/lib/cgi-bin/mailman/>
    AllowOverride None
    Options ExecCGI
    AddHandler cgi-script .cgi
    Order allow,deny
    Allow from all
    <IfVersion >= 2.4>
        Require all granted
    </IfVersion>
</Directory>
<Directory /var/lib/mailman/archives/public/>
    Options FollowSymlinks
    AllowOverride None
    Order allow,deny
    Allow from all
    <IfVersion >= 2.4>
        Require all granted
    </IfVersion>
</Directory>
<Directory /usr/share/images/mailman/>
    AllowOverride None
    Order allow,deny
    Allow from all
    <IfVersion >= 2.4>
        Require all granted
    </IfVersion>
</Directory>

</VirtualHost>
EOF
  describe file('/etc/apache2/sites-enabled/50-lists.openstack.org.conf') do
    its(:content) { should eq expected_vhost }
  end

  describe command('MAILMAN_SITE_DIR=/srv/mailman/openstack /usr/lib/mailman/bin/list_lists --bare') do
    its(:stdout) { should eq "kata-dev\n" }
  end
end
