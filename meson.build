project('geohashingwikihelper', ['c', 'vala'],
          version: '0.1.0',
    meson_version: '>= 0.50.0',
  default_options: [ 'warning_level=2',
                   ],
)

i18n = import('i18n')

#################
# Configuration #
#################
#conf_data = configuration_data()
#conf_data.set('GETTEXT_PACKAGE', meson.project_name())
#conf_data.set('LOCALE_DIR', join_paths(get_option('prefix'), get_option('localedir')))

#config = configure_file(input :
#	'config.h.in',
#	output : 'config.h',
#	configuration : conf_data)


subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('build-aux/meson/postinstall.py')

