#!/usr/bin/env python
from jinja2 import Template, Environment, FileSystemLoader
from subprocess import call
from os import remove

user='llparse'
versions=['latest', '0.24.1', '0.24.1-centos', '0.24.1-centos-7', '0.24.1-ubuntu', '0.24.1-ubuntu-14.04']
#versions=['0.24.1-ubuntu-14.04']
template_folders=['master', 'slave']

env = Environment(loader=FileSystemLoader('.'))

for version in versions:
  for template_folder in template_folders:
    template_path='{0}/Dockerfile.j2'.format(template_folder)
    template_out='{0}/Dockerfile.{0}.{1}'.format(template_folder, version)
    image='{0}/mesos-{1}:{2}'.format(user, template_folder, version)
    with open(template_out, 'w') as f:
      template = env.get_template(template_path)
      f.write(template.render(version=version))
    # TODO concurrency
    call(['docker', 'build', '-f', template_out, '-t', image, template_folder])
    call(['docker', 'push', image])
    remove(template_out)
