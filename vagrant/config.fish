function down
  sudo systemctl poweroff
end

function backend
  python3 /backend/uwsgi.py
end

function frontend
  env NODE_PATH="/frontend/node_modules" DEBUG="*,-express:router,-express:router:*" coffee /frontend/bin/launcher.coffee
end

function buyer
  env DEBUG="pe.fe:*" NODE_PATH="/frontend/node_modules" node /frontend/bin/bootstrap.buyer.js
end

function dealer
  env DEBUG="pe.fe:*" NODE_PATH="/frontend/node_modules" node /frontend/bin/bootstrap.dealer.js
end

function scr
    screen -s /usr/bin/fish -U -a -p 1
end

. /home/vagrant/venv/backend/bin/activate.fish
