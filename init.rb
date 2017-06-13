require 'redmine'

Redmine::Plugin.register :redmine_citrus_my_page_tools do
  name 'Redmine Citrus My Page Tools plugin'
  author 'take64'
  description 'This is a plugin for Redmine My Page'
  version '0.0.0.7'
  url 'http://github.com/take64'
  author_url 'http://besidesplus.net/'
  
  Rails.configuration.to_prepare do
    require_dependency 'my_controller'
    MyController.send(:helper, GrooveCalendarHelper)
    MyController.send(:helper, CitrusMyPageRenderHelper)
  end
end
