#
# Copyright (C) 2008 Pirmin Kalberer, Sourcepole AG
#
# This file is part of MapFish Server
#
# MapFish Server is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# MapFish Server is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with MapFish Server.  If not, see <http://www.gnu.org/licenses/>.
#

module MapfishCoreExtensions
  module ActiveRecord
    module Base

      def to_geojson(options = {})
        only = options.delete(:only)
        geoson = { :type => 'Feature' }
        geoson[:properties] = attributes.delete_if do |name, value|
          if value.is_a?(Geometry) then
            geoson[:geometry] = value if name == self.class.geometry_column.name
            true
          elsif name == self.class.primary_key then
            geoson[:id] = value
            true
          elsif only 
            !only.include?(name.to_sym)        
          end
        end
        geoson.to_json
      end

      def update_attributes_from_feature(feature)
        attr = feature.properties
        attr[self.class.geometry_column.name] = feature.geometry
        update_attributes(attr)
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def geometry_column
          #Returns first geometry column found. TODO: override by configuration (set_geometry_column)?
          @geometry_column ||= columns.detect {|col| col.respond_to?(:geometry_type) }
        end

        def params_from_geojson(geoson)
          name = self.to_s.downcase #unless geoson.is_a?(Array)
          data = geoson.delete(:properties) || {}
          data[geometry_column.name] = Geometry.from_geojson(geoson.delete(:geometry), geometry_column.srid)
          geoson.delete(:type)
          {name => data, primary_key => geoson.delete(:id)}
        end

        def mapfish_filter(params)
          filter = scoped

          #Create geometry filter
          srid = geometry_column.srid
          pnt = nil
          pnt = Point.from_x_y(params['lon'].to_f, params['lat'].to_f, srid) if params['lon'] && params['lat']
          box = nil
          if pnt && params['tolerance']
            rad = params['tolerance'].to_f/2
            box = [[pnt.x+rad, pnt.y+rad], [pnt.x-rad, pnt.y-rad], srid]
          end
          if params['bbox']
            x1, y1, x2, y2 = params['bbox'].split(',').collect(&:to_f)
            box = [[x1, y1], [x2, y2], srid]
          end
          if box
            box3d = "'BOX3D(#{box[0].join(" ")},#{box[1].join(" ")})'::box3d"
            filter = filter.where("#{table_name}.#{connection.quote_column_name(geometry_column.name)} && SetSRID(#{box3d}, #{box[2] || DEFAULT_SRID} ) ")
          end

          #Add attribute filter
          params.each do |key, value|
            next if value.nil? || !value.respond_to?(:empty?) || value.empty?
            field, op = key.split('__')
            col = "#{table_name}.#{connection.quote_column_name(field)}"
            case op
            when 'eq'
              filter = filter.where("#{col} = ?", value)
            when 'ne'
              filter = filter.where("#{col} <> ?", value)
            when 'lt'
              filter = filter.where("#{col} < ?", value)
            when 'lte'
              filter = filter.where("#{col} <= ?", value)
            when 'gt'
              filter = filter.where("#{col} > ?", value)
            when 'gte'
              filter = filter.where("#{col} >= ?", value)
            when 'ilike'
              #TODO: support wildcarded ILIKE: https://trac.mapfish.org/trac/mapfish/ticket/495
              filter = filter.where("#{col} ILIKE ?", value)
            end
          end

          filter
        end

        #Rails 2 backwards compatible finder
        def find_by_mapfish_filter(params, args = {})
          filter = {}
          #Create geometry filter
          srid = geometry_column.srid
          pnt = nil
          pnt = Point.from_x_y(params['lon'].to_f, params['lat'].to_f, srid) if params['lon'] && params['lat']
          box = nil
          if pnt && params['tolerance']
            rad = params['tolerance'].to_f/2
            box = [[pnt.x+rad, pnt.y+rad], [pnt.x-rad, pnt.y-rad], srid]
          end
          if params['bbox']
            x1, y1, x2, y2 = params['bbox'].split(',').collect(&:to_f)
            box = [[x1, y1], [x2, y2], srid]
          end
          if box
            box3d = "'BOX3D(#{box[0].join(" ")},#{box[1].join(" ")})'::box3d"
            filter = "#{table_name}.#{connection.quote_column_name(geometry_column.name)} && SetSRID(#{box3d}, #{box[2] || DEFAULT_SRID} ) "
          end
          conditions = sanitize_sql_for_conditions(filter)

          #Add attribute filter
          attrfilter = []
          params.each do |key, value|
            next if value.nil? || !value.respond_to?(:empty?) || value.empty?
            field, op = key.split('__')
            case op
            when 'eq'
              attrfilter << ["#{field} = ?", value]
            when 'ne'
              attrfilter << ["#{field} <> ?", value]
            when 'lt'
              attrfilter << ["#{field} < ?", value]
            when 'lte'
              attrfilter << ["#{field} <= ?", value]
            when 'gt'
              attrfilter << ["#{field} > ?", value]
            when 'gte'
              attrfilter << ["#{field} >= ?", value]
            when 'ilike'
              #TODO: support wildcarded ILIKE: https://trac.mapfish.org/trac/mapfish/ticket/495
              attrfilter << ["#{field} ILIKE ?", value]
            end
          end
          unless attrfilter.empty?
            sql, sqlparams = attrfilter.transpose
            if conditions.nil?
              conditions = ''
            else
              conditions << " AND "
            end
            conditions << sanitize_sql_for_conditions([sql.join(' AND ')] + sqlparams)
          end

          #Create finder arguments
          args.merge!(:conditions => conditions)
          args.merge!({:limit => params['maxfeatures'] }) if params['maxfeatures']
          args.merge!({:limit => params['limit'] }) if params['limit']
          args.merge!(:offset => params['offset']) if params['offset']
          find(:all, args)
        end
      end
    end
  end
end

if defined? ActiveRecord
  ActiveRecord::Base.class_eval do
    include MapfishCoreExtensions::ActiveRecord::Base
  end
end
