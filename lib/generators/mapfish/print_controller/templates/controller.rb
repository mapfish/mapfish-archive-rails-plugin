require 'print'

class <%= class_name %>Controller < ApplicationController
  include MapFish::Print::Controller

  def initialize
    @configFile = "#{Rails.root}/config/print.yaml"
  end

end
