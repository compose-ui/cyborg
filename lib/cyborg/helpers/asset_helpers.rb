module Cyborg
  module Helpers
    module AssetsHelper

      def cyborg_asset_url(file)
        Cyborg.plugin.asset_url(file)
      end

      def stylesheet_tag(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        tags = ''

        stylesheet_url(args).each do |url|
          tags += stylesheet_link_tag url, options
        end

        tags.html_safe
      end

      def javascript_tag(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        tags = ''

        javascript_url(args).each do |url|
          tags += javascript_include_tag url, options
        end

        tags.html_safe
      end

      def stylesheet_url(*args)
        Cyborg.plugin.stylesheets.urls(args)
      end

      def javascript_url(*args)
        Cyborg.plugin.javascripts.urls(args).uniq
      end

      def asset_tags
        stylesheet_tag + javascript_tag
      end

      def pin_tab_icon_tag(path, color="black")
        %Q{<link rel="mask-icon" mask href="#{cyborg_asset_url(path)}" color="#{color}">}.html_safe
      end

      def favicon_tag(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        source = args.first || 'favicon.ico'
        tag('link', {
          :rel  => 'shortcut icon',
          :type => 'image/x-icon',
          :href => cyborg_asset_url(source)
        }.merge!(options.symbolize_keys))
      end

      def sass_data(key=nil)
        if key
          Cyborg.plugin.stylesheets.data[key]
        else
          Cyborg.plugin.stylesheets.data
        end
      end
    end
  end
end

