require 'puppet/provider/parsedfile'

Puppet::Type.newtype(:mailman_list) do
  ensurable
  newparam(:name) do
    desc "The name of the mailing list."
  end

  newparam(:install) do
    desc "The mailmain installation to use."
  end
  newparam(:admin) do
    desc "The email address of the administrator."
  end
  newparam(:description) do
    desc "The description of the mailing list."
  end
  newparam(:mailserver) do
    desc "The FQDN of the mailing list host."
  end
  newparam(:password) do
    desc "The admin password for the list."
  end
  newparam(:provider) do
    desc "The backend to use for this mailman_list."
  end
  newparam(:webserver) do
    desc "The FQDN of the host providing web archives."
  end
end
