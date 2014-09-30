function down
  sudo shutdown -h now
end

function backend
  python3 /backend/uwsgi.py
end

. /home/vagrant/venv/backend/bin/activate.fish
