def prompt():
    from sys import exit
    from os.path import abspath

    steps = {
        'venv': {
            'label': 'virtual environment path',
            'default': 'venv/nix.dev'
        },
        'backend': {
            'label': 'backend project path',
            'default': 'backend'
        },
        'nginx': {
            'label': 'nginx configuration path',
            'default': '/etc/nginx/conf.d/parts-exchange.dev.conf'
        }
    }

    paths(steps)

    while True:
        print()
        print('Please verify configuration:')
        for item in steps.values():
            print('\t{0}: {1}'.format(item['label'], item['path']))
        confirmation = input('Is this correct? (y/n)').upper()
        if confirmation == 'N':
            print('Exiting...')
            exit(-1)
            break
        elif confirmation == 'Y':
            print()
            if check(steps):
                install(steps)
                exit(0)
            else:
                print('Cancelled')
                exit(-2)
            break


def paths(steps):
    from os.path import abspath

    for item in steps.values():
        item['path'] = abspath(input('Specify {0} [{1}]: '.format(item['label'], item['default'])) or item['default'])


def check(steps):
    from os.path import isfile, isdir

    if isfile(steps['venv']['path']):
        while True:
            action = input('venv path ({0}) is a file! (c)ancel, (s)kip, (o)verwrite: '.format(steps['venv']['path'])).upper()
            if action == 'C':
                return False
            elif action == 'S':
                steps['venv']['skip'] = True
                break
            elif action == 'O':
                steps['venv']['remove'] = True
                break
    elif isdir(steps['venv']['path']):
        while True:
            action = input('venv path ({0}) already exists. (c)ancel, (s)kip, (i)gnore, (o)verwrite: '.format(steps['venv']['path'])).upper()
            if action == 'C':
                return False
            elif action == 'S':
                steps['venv']['skip'] = True
                break
            elif action == 'I':
                steps['venv']['remove'] = False
                break
            elif action == 'O':
                steps['venv']['remove'] = True
                break

    if not isdir(steps['backend']['path']):
        print('FATAL! Backend path ({0}) is not a valid directory'.format(steps['backend']['path']))
        return False

    if isdir(steps['nginx']['path']):
        while True:
            action = input('nginx config path ({0}) is a directory. (c)ancel, (s)kip, (r)emove: '.format(steps['nginx']['path'])).upper()
            if action == 'C':
                return False
            elif action == 'S':
                steps['nginx']['skip'] = True
                break
            elif action == 'R':
                steps['nginx']['remove'] = True
                break
    elif isfile(steps['nginx']['path']):
        while True:
            action = input('nginx config path ({0}) already exists. (c)ancel, (s)kip, (o)verwrite: '.format(steps['nginx']['path'])).upper()
            if action == 'C':
                return False
            elif action == 'S':
                steps['nginx']['skip'] = True
                break
            elif action == 'O':
                steps['nginx']['remove'] = True
                break

    return True


def install(steps):
    from os import remove
    from os.path import join, isfile, isdir
    from shutil import rmtree
    from subprocess import Popen, PIPE
    from json import dumps

    if not steps['venv'].get('skip', False):
        print('## Installing virtual environment')
        if steps['venv'].get('remove', False):
            if isfile(steps['venv']['path']):
                remove(steps['venv']['path'])
            elif isdir(steps['venv']['path']):
                rmtree(steps['venv']['path'])
        Popen(['virtualenv', steps['venv']['path'], '--prompt=parts-exchange.develop\n']).communicate()

    if isfile(join(steps['venv']['path'], 'bin/activate')):
        with Popen(['bash'], stdin=PIPE) as proc:
            proc.stdin.write('source {0}\n'.format(join(steps['venv']['path'], 'bin/activate')).encode('utf-8'))
            print('## Installing required PIP packages')
            requirements = join(steps['backend']['path'], 'src/parts_exchange/requirements.txt')
            proc.stdin.write('pip install --allow-external=pyodbc --allow-unverified=pyodbc -r {0}'.format(requirements).encode('utf-8'))
            proc.communicate()
            proc.wait()
            if proc.returncode != 0:
                return

    if not steps['nginx'].get('skip', False):
        print('## Writing NGINX configuration')
        if steps['nginx'].get('remove', False):
            if isfile(steps['nginx']['path']):
                remove(steps['nginx']['path'])
            elif isdir(steps['nginx']['path']):
                rmtree(steps['nginx']['path'])

        with open(steps['nginx']['path'], 'w', encoding='utf-8') as nginx:
            nginx.write('upstream parts_exchange {\n')
            nginx.write('    server 127.0.0.1:7001;\n')
            nginx.write('}\n')
            nginx.write('\n')
            nginx.write('server {\n')
            nginx.write('    listen 7000;\n')
            nginx.write('    charset utf-8;\n')
            nginx.write('    location /api/ {\n')
            nginx.write('        uwsgi_pass parts_exchange;\n')
            nginx.write('        uwsgi_param QUERY_STRING $query_string;\n')
            nginx.write('        uwsgi_param REQUEST_METHOD $request_method;\n')
            nginx.write('        uwsgi_param CONTENT_TYPE $content_type;\n')
            nginx.write('        uwsgi_param CONTENT_LENGTH $content_length;\n')
            nginx.write('        uwsgi_param REQUEST_URI $request_uri;\n')
            nginx.write('        uwsgi_param PATH_INFO $document_uri;\n')
            nginx.write('        uwsgi_param DOCUMENT_ROOT $document_root;\n')
            nginx.write('        uwsgi_param SERVER_PROTOCOL $server_protocol;\n')
            nginx.write('        uwsgi_param HTTPS $https if_not_empty;\n')
            nginx.write('        uwsgi_param REMOTE_ADDR $remote_addr;\n')
            nginx.write('        uwsgi_param REMOTE_PORT $remote_port;\n')
            nginx.write('        uwsgi_param SERVER_PORT $server_port;\n')
            nginx.write('        uwsgi_param SERVER_NAME $server_name;\n')
            nginx.write('    }\n')
            nginx.write('}\n')

    if not steps['backend'].get('skip', False):
        print('## Writing backend configuration')
        with open(join(steps['backend']['path'], 'config.json'), 'w', encoding='utf-8') as backend:
            backend.write(dumps({
                'uwsgi': [
                    '--master',
                    '--enable-threads',
                    '--socket', ':7001'
                ]
            }) + '\n')

    if not steps['nginx'].get('skip', False):
        print('## Restarting NGINX')
        with Popen(['/etc/init.d/nginx', 'restart']) as proc:
            proc.communicate()
            proc.wait()
            if proc.returncode != 0:
                return


if __name__ == '__main__':
    prompt()
