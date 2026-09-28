class HomeController < ApplicationController
  def index
    render file: Rails.root.join("public/app/index.html"), layout: false
  end
end
