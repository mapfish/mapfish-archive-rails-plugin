# Mapfish server plugin for Ruby on Rails

/!\ This project is deprecated. See http://mapfish.org or http://mapfish.github.io/mapfish-website.



This HowTo describes step by step how to use [MapFish](http://www.mapfish.org/) Server Framework to 
set up a MapFish project. A MapFish project defines Web Services on which MapFish Client components 
can rely. See [here](http://trac.mapfish.org/trac/mapfish/wiki/MapFishProtocol) for a description 
of the interfaces provided by MapFish Web Services.

The Mapfish server for Ruby is implemented as a plugin for the [Ruby on Rails](http://www.rubyonrails.org/) framework.

A sample application is available at [GitHub](http://github.com/pka/mapfish-rails-sample-app/tree).

## Create a MapFish project

Create a new Rails project:
```
    rails new MyMapFishProject --database=postgresql
    cd MyMapFishProject
```
Rails 3: Add the mapfish plugin to your Gemfile:
```
  gem 'mapfish'
```
Then from your project’s RAILS_ROOT, run:
```
  bundle install
```
Rails 2: Add the mapfish plugin to your config/environment.rb:
```
  config.gem 'mapfish'
```
Then from your project’s RAILS_ROOT, run:
```
  rake gems:install
```
It is also possible to install mapfish as a plugin:
```
  script/plugin install http://www.mapfish.org/svn/mapfish/implementations/rails-plugin/mapfish/trunk
```
Install the latest version of the Mapfish client libraries:
```
  rake mapfish:install_client
```
## Set up the PostGIS database

If you don't have PostGIS database template yet, create one:
```
  sudo su - postgres
  createdb -E UTF8 template_postgis # Create the template spatial database.
  createlang -d template_postgis plpgsql # Adding PLPGSQL language support.
  psql -d template_postgis -f /usr/share/postgresql-8.3-postgis/lwpostgis.sql
  psql -d template_postgis -f /usr/share/postgresql-8.3-postgis/spatial_ref_sys.sql
  cat <<EOS | psql -d template_postgis
  UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';
  REVOKE ALL ON SCHEMA public FROM public;
  GRANT USAGE ON SCHEMA public TO public;
  GRANT ALL ON SCHEMA public TO postgres;
  GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE public.geometry_columns TO PUBLIC;
  GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE public.spatial_ref_sys TO PUBLIC;
  VACUUM FULL FREEZE;
  EOS
```
Change the connection properties in ``config/database.yml``.
Add a line ``template: template_postgis`` for each environment.

Create the development database, if it does not exist:
```
  rake db:create
```
## Set up layers

You now need to create layers. In effect, a layer corresponds to a PostGIS table.

Create a resource (model and controller):
```
  rails generate mapfish:resource WeatherStation name:string geom:point --skip-timestamps --skip-fixture
  rake db:migrate
```
Import some data:
```
  rails runner "Geonames::Weather.weather(:north => 44.1, :south => -9.9, :east => -22.4, :west => 55.2).each { |st| WeatherStation.create(:name => st.stationName, :geom => Point.from_x_y(st.lng, st.lat)) }"
```
(needs lib/geonames.rb from http://github.com/pka/map_layers/raw/master/lib/geonames.rb)

Create a resource for an existing table:
```
  rails generate mapfish:resource Country --skip-migration --skip-fixture
```

Insert table name and custom id in ``app/models/country.rb``:
```
  set_table_name "world_factbk_simplified"
  set_primary_key "gid"
```

## Starting the web server

You should be all set now. Try starting the web server:
```
  rails server
```

and checkout ``http://localhost:3000/countries?maxfeatures=10``

Your browser should be displaying a nice GeoJSON object!

You can now go back to your webpage and configure MapFish widgets to access your layer through the URL ``http://localhost:3000/countries``.


For running in production mode you should build and install the compressed runtime libraries:
```
   rake mapfish:build_scripts
   rake mapfish:copy_scripts
```

The development libraries in public/mfbase are not needed in a production deployment and the
CSS and Javascript files can be included from public/javascripts:
```
   <link rel="stylesheet" type="text/css" href="javascripts/ext/resources/css/ext-all.css" />
   <link rel="stylesheet" type="text/css" href="javascripts/mapfish/mapfish.css" />

   <script type="text/javascript" src="javascripts/ext/adapter/ext/ext-base.js"></script>
   <script type="text/javascript" src="javascripts/ext/ext-all.js"></script>
   <script type="text/javascript" src="javascripts/mapfish/MapFish.js"></script>
```

## Using the print module

The Rails MapFish plugin can generate a controller for the `MapFish print protocol <http://trac.mapfish.org/trac/mapfish/wiki/PrintModuleDoc#Protocol>`_, to produce PDF outputs of your maps. (see `MapFish PrintModuleDoc <http://trac.mapfish.org/trac/mapfish/wiki/PrintModuleDoc>`_):

```
  rails generate mapfish:print_controller Print
```

You'll need to have `Sun's JRE <http://www.java.com/download/>`_ installed to make this working.

* The print module should be ready & responding to /print/info.json to get print configuration.
  Don't forget to adapt config/print.yaml (see `configuration <http://trac.mapfish.org/trac/mapfish/wiki/PrintModuleServer>`_. For instance, you should at least allow the print service to access the WMS services you're using.
  If you're getting errors, check your log file to get debug information.

* Once this is done, you can integrate the `MapFish print widgets <http://www.mapfish.org/svn/mapfish/trunk/MapFish/client/mfbase/mapfish/widgets/print/>`_ into your client application, which give you the ability to output nice customizable PDF with your maps. Examples can be `found here <http://demo.mapfish.org/mapfishsample/trunk/examples/print/>`_.


## License

The Mapfish server plugin for Rails is released under the LGPL license.

*Copyright (c) 2008-2010 Pirmin Kalberer, Sourcepole AG*
