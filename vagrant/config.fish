function down
  sudo shutdown -h now
end

function backend
  python3 /backend/uwsgi.py
end

function frontend
  env NODE_PATH="/frontend/node_modules" DEBUG="*,-express:router,-express:router:*" coffee /frontend/bin/launcher.coffee
end

function scr
    screen -s /usr/bin/fish -U -a -p 1
end

. /home/vagrant/venv/backend/bin/activate.fish
