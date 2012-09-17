[![Build Status](https://secure.travis-ci.org/zevarito/mixpanel.png)](http://travis-ci.org/zevarito/mixpanel)

## Table of Contents

- [What is Mixpanel] (#what-is-mixpanel)
- [What does this Gem do?] (#what-does-this-gem-do)
- [Install] (#install)
  - [Rack Middleware] (#rack-middleware) 
- [Usage] (#usage)
  - [Initialize Mixpanel class] (#initialize-mixpanel-class) 
- [Examples] (#examples)
 - [How to use it from Rails controllers] (#how-to-use-it-from-rails-controllers)
 - [How to track events using Resque and Rails] (#how-to-track-events-using-resque-and-rails)
- [Supported Platforms] (#supported-platforms)
- [Deprecation Notes] (#deprecation-notes)
- [Collaborators and Maintainers] (#collaborators-and-maintainers)

## What is Mixpanel

Mixpanel is a real-time analytics service that helps companies understand how users interact with web applications.
http://mixpanel.com

## What does this Gem do?

- Track events with properties directly from your backend.
- Track events with properties through javascript using a rack middleware.

## Install

```ruby
  gem install mixpanel
```

### Rack Middleware

*Only need if you want to track events from Javascript.*

If you are using Rails you can add this to your specific environment configuration file (located in config/environments/) or create a new
initializer for it:

```ruby
  config.middleware.use "Mixpanel::Tracker::Middleware", "YOUR_MIXPANEL_API_TOKEN", options
```

Where **options** is a Hash that accepts the following keys:

* **insert_js_last** : true | false

  *Default: false*.
  By default the scripts are inserted into the head of the html response. If you'd prefer the scripts to run after
  all rendering has completed you can set the insert_js_last flag and they'll be added at the end of the body tag.
  This will work whether or not you opt for the aynchronous version of the API. However, when inserting js into an
  ajax response it will have no effect.

* **persist** : true | false

  *Default: false*.
  If you would like, the Mixpanel gem may be configured to store its queue in a Rack session. This allows events
  to be stored through redirects, helpful if you sign in and redirect but want to associate an event with that
  action. The mixpanel gem will also remove duplicate events from your queue for information that should only be
  trasmitted to the API once, such as `mixpanel.identify`, `mixpanel.name_tag`, `mixpanel.people.set`, and
  `mixpanel.register`.
  This allows you to use a before filter to set these variables, redirect, and still have them only transmitted
  once.
  *To enable persistence*, you must set it in both places, Middleware and when you initialize Mixpanel class.

* **config** : a Hash

  *Default: {}*.

  You can also pass Mixpanel configuration details as seen here
  (https://mixpanel.com/docs/integration-libraries/javascript-full-api#set_config)

## Usage

### Initialize Mixpanel class

```ruby
  @mixpanel = Mixpanel::Tracker.new("YOUR_MIXPANEL_API_TOKEN", request.env, options)
```
Where **options** is a Hash that accepts the following keys:

* **async** : true | false
  
  *Default: false*.
  Built in async feature. Events are sent to a subprocess via a pipe and the sub process which asynchronously send events to Mixpanel.
  This process uses a single thread to upload events, and may start dropping events if your application generates
  them at a very high rate.
  If you like for a more robust async behavior take a look at Resque example.

* **url** : String
 
  *Default: http://api.mixpanel.com/track/?data=*.
  If you are proxying Mixpanel API requests then you can set a custom url and additionally stop the token from
  being sent by marking it as false if you're going to let the proxy add it.
  Example: { url: "http://localhost:8000/mixpanelproxy?data=" }.

* **persist** : true | false

  *Default: false*.
  If you would like, the Mixpanel gem may be configured to store its queue in a Rack session. This allows events
  to be stored through redirects, helpful if you sign in and redirect but want to associate an event with that
  action. The mixpanel gem will also remove duplicate events from your queue for information that should only be
  trasmitted to the API once, such as `mixpanel.identify`, `mixpanel.name_tag`, `mixpanel.people.set`, and
  `mixpanel.register`.
  This allows you to use a before filter to set these variables, redirect, and still have them only transmitted
  once.
  *To enable persistence*, you must set it in both places, Middleware and when you initialize Mixpanel class.

  *To enable import mode* you must set both :import => true and :api_key => YOUR_KEY (not to be confused with the project token.)
  You can get more information about import mode here
  (https://mixpanel.com/docs/api-documentation/importing-events-older-than-31-days)

### Track events directly.

```ruby
  @mixpanel.track_event("Sign in", {:some => "property"})
```

### Append events to be tracked with Javascript.

*Note*: You should setup the [Rack Middleware](#rack-middleware).

```ruby
  @mixpanel.append_event("Sign in", {:some => "property"})
```

### Execute Javascript API call

*Note*: You should setup the [Rack Middleware](#rack-middleware).

```ruby
  @mixpanel.append_api("register", {:some => "property"})
  @mixpanel.append_api("identify", "Unique Identifier")
```

## Examples

### How to use it from Rails controllers?
  
In your ApplicationController class add a method to instantiate mixpanel.

```ruby
  before_filter :initialize_mixpanel

  def initialize_mixpanel
    @mixpanel = Mixpanel::Tracker.new("YOUR_MIXPANEL_API_TOKEN", request.env, options)
  end
```
## How to track events using Resque and Rails

If you don't want to use the built in Mixpanel Gem async feature bellow there is an example about how to make
async calls using Resque.

[Resque is a Redis-backed Ruby library for creating background jobs](https://github.com/defunkt/resque)

```ruby
    class MixpanelTrackEventJob
      @queue = :slow

      def mixpanel(request_env)
        Mixpanel::Tracker.new(MIXPANEL_TOKEN, request_env)
      end

      def perform(name, params, request_env)
        mixpanel(request_env).track_event(name, params)
      end
    end
```

```ruby
    class UsersController < ApplicationController
      def create
        @user = User.new(params[:user])

        if @user.save
          MixpanelTrackEventJob.enqueue("Sign up", {:invited => params[:invited]}, request.env)
          redirect_to user_root_path
        else
          render :new
        end
     end
   end
```

## Supported Ruby Platforms

- 1.8.7
- 1.9.2
- 1.9.3
- JRuby 1.8 Mode

## Deprecation Notes

This way to initialize Mixpanel gem is not longer allowed. 

```ruby
  Mixpanel.new
```

Use this instead:

```ruby
  Mixpanel::Tracker.new
```

## Collaborators and Maintainers

* [Alvaro Gil](https://github.com/zevarito) (Author)
* [Nathan Baxter](https://github.com/LogicWolfe)
* [Jake Mallory](https://github.com/tinomen)
* [Logan Bowers](https://github.com/loganb)
* [jakemack](https://github.com/jakemack)
* [James Ferguson](https://github.com/JamesFerguson)
* [Brad Wilson](https://github.com/bradx3)
* [Mark Cheverton](https://github.com/ennui2342)
* [Jamie Quint](https://github.com/jamiequint)
* [Ryan Schmukler](https://github.com/rschmukler)
* [Travis Pew](https://github.com/travisp)
