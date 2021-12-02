geohashingwikihelper_sources = [
  'Geohashing/Date.vala',
  'Geohashing/Graticule.vala',
  'Geohashing/SpecificHash.vala',

  'main.vala',
  'MainWindow.vala',
  'TextListingDialog.vala',
  'HashPopover.vala',
  'AccountPopover.vala',
  'GalleryTab.vala',
  'MediaWiki.vala',
]

geohashingwikihelper_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),

  dependency('libsoup-2.4'),
  dependency('json-glib-1.0'),
]

gnome = import('gnome')

geohashingwikihelper_sources += gnome.compile_resources('geohashingwikihelper-resources',
  'geohashingwikihelper.gresource.xml',
  c_name: 'geohashingwikihelper'
)

executable('geohashingwikihelper', geohashingwikihelper_sources,
#  config,
  vala_args: '--target-glib=2.50',  dependencies: geohashingwikihelper_deps,
  install: true,
)

