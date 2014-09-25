def prompt():
    from sys import exit
    from os.path import abspath

    labels = {
        'venv_path': 'virtual environment path',
        'nginx_path': 'nginx conf.d path',
        'backend_path': 'backend project path'
    }
    defaults = {
        'venv_path': 'venv/nix.dev',
        'nginx_path': '/etc/nginx/conf.d',
        'backend_path': 'backend'
    }
    values = {
        'venv_path': abspath(
            input('Specify {0} [{1}]:'.format(labels['venv_path'], defaults['venv_path'])) or defaults['venv_path']),
        'nginx_path': abspath(
            input('Specify {0} [{1}]:'.format(labels['nginx_path'], defaults['nginx_path'])) or defaults['nginx_path']),
        'backend_path': abspath(
            input('Specify {0} [{1}]:'.format(labels['backend_path'], defaults['backend_path'])) or defaults[
                'backend_path'])
    }

    while True:
        print()
        print('Please verify configuration:')
        print('\t{0}: {1}'.format(labels['venv_path'], values['venv_path']))
        print('\t{0}: {1}'.format(labels['nginx_path'], values['nginx_path']))
        print('\t{0}: {1}'.format(labels['backend_path'], values['backend_path']))
        confirmation = input('Is it correct? (y/n)')
        if confirmation == 'n':
            print('Exiting...')
            exit(-1)
        elif confirmation == 'y':
            print()
            install(**values)
            exit(0)


def install(venv_path, nginx_path, backend_path):
    from os.path import join
    from subprocess import Popen, PIPE
    from json import dumps

    print('## Installing virtual environment')
    Popen(['virtualenv', venv_path, '--prompt=parts-exchange.develop']).communicate()

    with Popen(['bash'], stdin=PIPE) as proc:
        proc.stdin.write('source {0}\n'.format(join(venv_path, 'bin/activate')).encode('utf-8'))
        print('## Installing required PIP packages')
        proc.stdin.write('pip install -r {0}'.format(join(backend_path, 'src/parts_exchange/requirements.txt')).encode('utf-8'))
        proc.communicate()
        proc.wait()

    print('## Patching NGINX configuration')
    with open(join(nginx_path, 'parts-exchange.develop.conf'), 'w', encoding='utf-8') as nginx:
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

    print('## Writing backend configuration')
    with open(join(backend_path, 'config.json'), 'w', encoding='utf-8') as backend:
        backend.write(dumps({
            'uwsgi': [
                '--master',
                '--enable-threads',
                '--socket', ':7001'
            ]
        }) + '\n')

    print('## Restarting NGINX')
    with Popen(['/etc/init.d/nginx', 'restart']) as proc:
        proc.communicate()
        proc.wait()


if __name__ == '__main__':
    prompt()
