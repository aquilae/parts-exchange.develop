echo
echo "## Making YUM cache"
yum -y makecache
yum -y install deltarpm
yum -y install make automake gcc gcc-c++ kernel-devel

echo
echo "## Checking unixODBC"
yum -y install unixODBC unixODBC-devel
if [ ! -f /usr/lib64/libodbc.so.1 ] ; then
	ln -s /usr/lib64/libodbc.so.2 /usr/lib64/libodbc.so.1
fi
if [ ! -f /usr/lib64/libodbcinst.so.1 ] ; then
	ln -s /usr/lib64/libodbcinst.so.2 /usr/lib64/libodbcinst.so.1
fi

echo
echo "## Checking Microsoft SQL Server ODBC Driver"
if [ ! -f /home/vagrant/sqlncli-11.0.1790.0.tar.gz ] ; then
	cp /vagrant/sqlncli-11.0.1790.0.tar.gz /home/vagrant
fi
if [ ! -d /home/vagrant/sqlncli-11.0.1790.0 ] ; then
	(cd /home/vagrant && tar -xf sqlncli-11.0.1790.0.tar.gz )
fi
if ! which sqlcmd 2>/dev/null >/dev/null ; then
	# sed 's|req_dm_ver="2.3.0"|req_dm_ver="2.3.2"|' /home/vagrant/sqlncli-11.0.1790.0/install.sh > /home/vagrant/sqlncli-11.0.1790.0/install.sh.patched
	# bash /home/vagrant/sqlncli-11.0.1790.0/install.sh.patched install --force --accept-license 2>/dev/null
	(cd /home/vagrant/sqlncli-11.0.1790.0 && chmod +x ./install.sh && bash ./install.sh install --force --accept-license)
fi

echo
echo "## Checking FISH"
if ! which fish 2>/dev/null >/dev/null ; then
	yum -y install fish
fi

echo
echo "## Checking NGINX"
if ! which nginx 2>/dev/null >/dev/null ; then
	yum -y install nginx
fi

echo
echo "## Checking Python 3k"
if ! which python3 2>/dev/null >/dev/null ; then
	yum -y install python3 python3-devel
fi

echo
echo "## Checking Python 3k PIP"
if ! which pip-python3 2>/dev/null >/dev/null ; then
	yum -y install python3-pip
fi

echo
echo "## Checking virtualenv"
if ! which virtualenv 2>/dev/null >/dev/null ; then
	pip-python3 install virtualenv
fi

echo
echo "## Checking FISH config"
if [ ! -f /home/vagrant/.config/fish/config.fish ] ; then
	mkdir -p /home/vagrant/.config/fish
	ln -s /vagrant/config.fish /home/vagrant/.config/fish/config.fish
fi

echo
echo "## Checking NGINX config"
if [ ! -f /etc/nginx/conf.d/parts-exchange.conf ] ; then
	ln -s /vagrant/nginx.conf /etc/nginx/conf.d/parts-exchange.conf
fi
nginx -t && service nginx restart

echo
echo "## Creating Backend environment"
if [ ! -d /home/vagrant/venv/backend ] ; then
	virtualenv /home/vagrant/venv/backend --prompt="(venv:parts-exchange.backend) "
fi

echo
echo "## Entering Backend virtual environment"
source /home/vagrant/venv/backend/bin/activate

echo
echo "### Installing PIP packages required for Backend"
pip-python3 install --upgrade -r /backend/src/parts_exchange/requirements.txt
