class <%= controller_class_name %>Controller < ApplicationController

  SRID = <%= class_name %>.geometry_column.srid

<% unless options[:singleton] -%>
  # GET /<%= table_name %>
  def index
    @<%= table_name %> = <%= class_name %>.mapfish_filter(params)

    render :json => @<%= table_name %>.to_geojson
  end
<% end -%>

  # GET /<%= table_name %>/1
  def show
    @<%= file_name %> = <%= orm_class.find(class_name, "params[:id]") %>

    render :json => [@<%= file_name %>].to_geojson
  end

  # POST /<%= table_name %>
  def create
    @<%= table_name %> = []
    feature_collection = Geometry.from_geojson(request.raw_post, SRID)
    if feature_collection.nil?
      head :bad_request
      return
    end

    feature_collection.features.each do |feature|
      if feature.id.is_a? Integer
        <%= file_name %> = <%= orm_class.find(class_name, "feature.id") %>
      end
      if <%= file_name %>.nil?
        <%= file_name %> = <%= orm_class.build(class_name) %>
      end

      if <%= file_name %>.update_attributes_from_feature(feature)
        @<%= table_name %> << <%= file_name %>
      end
    end

    render :json => @<%= table_name %>.to_geojson, :status => :created
  end

  # PUT /<%= table_name %>/1
  def update
    feature = Geometry.from_geojson(request.raw_post, SRID)
    if feature.nil?
      head :bad_request
      return
    end

    if feature.id.is_a? Integer
      @<%= file_name %> = <%= orm_class.find(class_name, "feature.id") %>
    end
    if @<%= file_name %>.nil?
      head :not_found
      return
    end

    if @<%= file_name %>.update_attributes_from_feature(feature)
      render :json => @<%= file_name %>.to_geojson, :status => :created
    else
      head :unprocessable_entity
    end
  end

  # DELETE /<%= table_name %>/1
  def destroy
    @<%= file_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    @<%= orm_instance.destroy %>
    head :no_content
  end
end
