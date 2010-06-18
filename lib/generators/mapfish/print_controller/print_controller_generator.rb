module Mapfish
  class PrintControllerGenerator < Rails::Generators::NamedBase
    check_class_collision :suffix => "Controller"

    def self.source_root
      @source_root ||= File.expand_path('../templates', __FILE__)
    end

    def create_controller_files
      template 'controller.rb', File.join('app/controllers', class_path, "#{file_name}_controller.rb")
    end

    def create_config_files
      template 'config.yaml', File.join('config', class_path, "print.yaml")
    end

    def add_routes
      route %{match '#{file_name}/:id.:format' => "#{file_name}#show", :via => :get}
      route %{match '#{file_name}/create.:format' => "#{file_name}#create", :via => :post}
      route %{match '#{file_name}/info.:format' => "#{file_name}#info", :via => :get}
    end

    hook_for :helper, :as => :controller, :in => :rails
  end
end
