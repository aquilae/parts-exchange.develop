echo
echo "## Making YUM cache"
yum -y makecache
yum -y install deltarpm
yum -y install make automake gcc gcc-c++ kernel-devel

if ! which screen 2>/dev/null >/dev/null ; then
    yum -y install screen
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
if [ ! -d /frontend/src ] ; then
    rm -f /frontend/src
    mkdir /frontend/src
fi
if [ ! -d /frontend/src/server ] ; then
    rm -f /frontend/src/server
    mkdir /frontend/src/server
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
if [ -d /frontend_ntfs/bin ] ; then
    cd /frontend_ntfs/bin
    for P in * ; do
        if [ ! -f "/frontend/bin/$P" ] ; then
            if [ ! -d "/frontend/bin/$P" ] ; then
                echo "link: /frontend/bin/$P => /frontend_ntfs/bin/$P"
                ln -s "/frontend_ntfs/bin/$P" "/frontend/bin/$P"
            fi
        fi
    done
fi
if [ -d /frontend_ntfs/src ] ; then
    cd /frontend_ntfs/src
    for P in * ; do
        if [ ! -f "/frontend/src/$P" ] ; then
            if [ ! -d "/frontend/src/$P" ] ; then
                echo "link: /frontend/src/$P => /frontend_ntfs/src/$P"
                ln -s "/frontend_ntfs/src/$P" "/frontend/src/$P"
            fi
        fi
    done
fi
if [ -d /frontend_ntfs/src/server ] ; then
    cd /frontend_ntfs/src/server
    for P in * ; do
        if [ ! -f "/frontend/src/server/$P" ] ; then
            if [ ! -d "/frontend/src/server/$P" ] ; then
                echo "link: /frontend/src/server/$P => /frontend_ntfs/src/server/$P"
                ln -s "/frontend_ntfs/src/server/$P" "/frontend/src/server/$P"
            fi
        fi
    done
fi

echo
echo "### Installing npm packages required for Frontend"
(cd /frontend && npm install)
