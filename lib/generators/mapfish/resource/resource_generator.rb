require 'rails/generators/rails/resource/resource_generator'

module Mapfish
  class ResourceGenerator < Rails::Generators::ResourceGenerator
    remove_hook_for :resource_controller
    remove_class_option :actions

    def self.source_root
      @source_root ||= File.expand_path('../templates', __FILE__)
    end

    def create_controller_files
      template 'controller.rb', File.join('app/controllers', class_path, "#{controller_file_name}_controller.rb")
    end

    # Invoke the helper using the controller name (pluralized)
    hook_for :helper, :in => :rails, :as => :scaffold do |invoked|
      invoke invoked, [ controller_name ]
    end

  end
end
