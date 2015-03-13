echo
echo "## Making YUM cache"
# yum -y makecache
# yum -y install deltarpm
# yum -y install make automake gcc gcc-c++ kernel-devel

if ! which yum-config-manager >/dev/null ; then
    yum -y install yum-utils
fi

if ! which screen 2>/dev/null >/dev/null ; then
    yum -y install screen
fi

if ! which git 2>/dev/null >/dev/null ; then
    yum -y install git
fi

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
echo "## Checking Mono"
if ! which mono --version 2>/dev/null >/dev/null ; then
    rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
    yum-config-manager --add-repo http://download.mono-project.com/repo/centos/
    yum -y install mono-complete
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
echo "## Checking Node.JS"
if ! which node 2>/dev/null >/dev/null ; then
    yum -y install nodejs
fi

echo
echo "## Checking npm"
if ! which npm 2>/dev/null >/dev/null ; then
    yum -y install npm
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
nginx -t && systemctl restart nginx

echo
echo "## Checking Backend config [DISABLED]"
# if [ ! -f /backend/config.json ] ; then
#     echo > /backend/config.json
# fi

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
pip3 install --upgrade -r /backend/src/parts_exchange/requirements.txt --allow-external=pyodbc --allow-unverified=pyodbc

echo
echo "### Creating Frontend symlink environment"
if [ ! -d /frontend ] ; then
    rm -f /frontend
    mkdir /frontend
fi
if [ ! -d /frontend/node_modules ] ; then
    rm -f /frontend/node_modules
    mkdir /frontend/node_modules
fi
if [ -d /frontend_ntfs ] ; then
    cd /frontend_ntfs
    for P in * ; do
        if [ ! -f "/frontend/$P" ] ; then
            if [ ! -d "/frontend/$P" ] ; then
                echo "link: /frontend/$P => /frontend_ntfs/$P"
                ln -s "/frontend_ntfs/$P" "/frontend/$P"
            fi
        fi
    done
fi

echo
echo "### Installing npm packages required for Frontend"
(cd /frontend && npm install)
