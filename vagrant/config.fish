function down
  sudo shutdown -h now
end

function backend
  python3 /backend/uwsgi.py
end

function frontend
  env NODE_PATH="/frontend/src/server/node_modules" DEBUG="*,-express:router,-express:router:*" node /frontend/src/server/bin/www.js
end

function scr
    screen -s /usr/bin/fish -U -a -p 1
end

. /home/vagrant/venv/backend/bin/activate.fish
