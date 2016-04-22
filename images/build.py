#!/usr/bin/env python
from jinja2 import Template, Environment, FileSystemLoader
from subprocess import call
from os import listdir, remove

user='llparse'
projects=['mesos-base', 'mesos-master', 'mesos-slave', 'marathon', 'chronos', 'kafka']

for project in projects:
  generated=[]
  # Render templates
  for filename in listdir(project):
    env = Environment(
      loader=FileSystemLoader(project),
      trim_blocks=True)

    if filename.endswith('.j2'):
      with open('{0}/{1}'.format(project, filename[:-3]), 'w') as f:
        template = env.get_template(filename)
        f.write(template.render(user=user))
      generated+=[filename[:-3]]
  # Give shell scripts executable permission
  for filename in listdir(project):
    if filename.endswith('.sh'):
      call(['chmod', '+x', '{0}/{1}'.format(project, filename)])

  # Build and push
  image='{0}/{1}:latest'.format(user, project)  

  call(['docker', 'build', '-t', image, project])

  for filename in generated:
    remove('{0}/{1}'.format(project, filename))

  call(['docker', 'push', image])

