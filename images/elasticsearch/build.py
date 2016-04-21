#!/usr/bin/env python
from jinja2 import Template, Environment, FileSystemLoader
from subprocess import call
from os import remove

user='llparse'
versions=['1.0.1-ubuntu-14.04']
types=['scheduler']

env = Environment(
  loader=FileSystemLoader('./templates'),
  trim_blocks=True)

for version in versions:
  for t in types:
    image='{0}/elasticsearch-{1}:{2}'.format(user, t, version)
    dockerfile='Dockerfile.{0}.{1}'.format(t, version)
    entrypoint='entrypoint.sh'

    with open(dockerfile, 'w') as f:
      template = env.get_template('Dockerfile.j2')
      f.write(template.render(version=version, type=t))

    with open(entrypoint, 'w') as f:
      template = env.get_template('entrypoint.sh.j2')
      f.write(template.render(
        version=version, 
        type=t, 
        entrypoint=entrypoint))
      
    call(['chmod', '+x', entrypoint])
    call(['docker', 'build', '-f', dockerfile, '-t', image, '.'])
    call(['docker', 'push', image])
    remove(dockerfile)
    remove(entrypoint)
