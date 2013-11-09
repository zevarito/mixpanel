require "uri"
require "net/http"
require 'json'
require 'thread'
require 'base64'

module Mixpanel
  class Tracker
    require 'mixpanel/async'
    require 'mixpanel/event'
    require 'mixpanel/person'

    extend Mixpanel::Async
    include Mixpanel::Event
    include Mixpanel::Person

    def initialize(token, options={})
      @token = token
      @async = !!options.fetch(:async, false)
      @persist = !!options.fetch(:persist, false)
      @env = options.fetch :env, {}
      @api_key = options.fetch :api_key, nil

      # Make sure queue object is instantiated to an array.  If not persisted, set queue object to empty array.
      if @persist
        @env['rack.session'] ||= {}
        @env['rack.session']['mixpanel_events'] ||= []
      else
        @env['mixpanel_events'] = []
      end
    end

    def queue
      @persist ? @env['rack.session']['mixpanel_events'] : @env['mixpanel_events']
    end

    def append(type, *args)
      js_args = args.collect do |arg|
        escape_object_for_js(arg).to_json
      end
      queue << [type, js_args]
    end

    protected

    def ip
        (@env['HTTP_X_FORWARDED_FOR'] || @env['REMOTE_ADDR'] || '').split(',').last
    end

    # Walk through each property and see if it is in the special_properties.
    # If so, change the key to have a $ in front of it.
    def properties_hash(properties, special_properties)
      properties.inject({}) do |props, (key, value)|
        key = "$#{key}" if special_properties.include?(key.to_s)
        value = value.to_i if value.class == Time
        props[key.to_sym] = value
        props
      end
    end

    def encoded_data(parameters)
      Base64.encode64(JSON.generate(parameters)).gsub(/\n/,'')
    end

    def post_request(url, data, async)
      if async
        send_async(url, data)
      else
        Net::HTTP.post_form(::URI.parse(url), data)
      end
    end

    def parse_response(response)
      if response.respond_to?(:body)
        response.body.to_i == 1
      else
        response.to_i == 1
      end
    end

    def send_async(url, data)
      w = Mixpanel::Tracker.worker
      begin
        url << "\n"
        w.write JSON.dump(data.merge(:_mixpanel_url => url))
        1
      rescue Errno::EPIPE => e
        Mixpanel::Tracker.dispose_worker w
        0
      end
    end

    private

    # Recursively escape anything in a primitive, array, or hash, in
    # preparation for jsonifying it
    def escape_object_for_js(object, i = 0)

      if object.kind_of? Hash
        # Recursive case
        Hash.new.tap do |h|
          object.each do |k, v|
            h[escape_object_for_js(k, i + 1)] = escape_object_for_js(v, i + 1)
          end
        end

      elsif object.kind_of? Enumerable
        # Recursive case
        object.map do |elt|
          escape_object_for_js(elt, i + 1)
        end

      elsif object.respond_to? :iso8601
        # Base case - safe object
        object.iso8601

      elsif object.kind_of?(Numeric)
        # Base case - safe object
        object

      elsif [true, false, nil].member?(object)
        # Base case - safe object
        object

      else
        # Base case - use string sanitizer from ActiveSupport
        escape_javascript(object.to_s)

      end
    end

    # All this code borrowed from rails/action_pack - ActionView::Helpers::JavascriptHelper

    JS_ESCAPE_MAP = {
                     '\\'    => '\\\\',
                     '</'    => '<\/',
                     "\r\n"  => '\n',
                     "\n"    => '\n',
                     "\r"    => '\n',
                     '"'     => '\\"',
                     "'"     => "\\'"
                    }

    JS_ESCAPE_MAP["\342\200\250".force_encoding(Encoding::UTF_8).encode!] = '&#x2028;'
    JS_ESCAPE_MAP["\342\200\251".force_encoding(Encoding::UTF_8).encode!] = '&#x2029;'

    # Escapes carriage returns and single and double quotes for JavaScript segments.
    #
    # Also available through the alias j(). This is particularly helpful in JavaScript
    # responses, like:
    #
    #   $('some_element').replaceWith('<%=j render 'some/element_template' %>');
    def escape_javascript(javascript)
      if javascript
        javascript.gsub(/(\\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"'])/u) {|match| JS_ESCAPE_MAP[match] }
      else
        ''
      end
    end
  end
end
