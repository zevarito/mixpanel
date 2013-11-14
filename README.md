# Important News

This Gem will not be maintained anymore, there is an Official gem being developed and we encourage you to use that gem from now on.

We will merge PR for bugs for a little period of time, but no new features will be added.

[Official Gem repository](https://github.com/mixpanel/mixpanel-ruby)

# Needed updates

Upgrade to version 4.1.0 to avoid XSS Vulnerability

## Table of Contents

- [What is Mixpanel] (#what-is-mixpanel)
- [What does this Gem do?] (#what-does-this-gem-do)
- [Install] (#install)
  - [Rack Middleware] (#rack-middleware)
- [Usage] (#usage)
  - [Initialize Mixpanel] (#initialize-mixpanel)
    - [Track Events Directly](#track-events-directly)
    - [Pixel Based Event Tracking](#pixel-based-event-tracking)
    - [Redirect Based Event Tracking](#redirect-based-event-tracking)
    - [Import Events](#import-events)
    - [Set Person Attributes Directly](#set-person-attributes-directly)
    - [Increment Person Attributes Directly](#increment-person-attributes-directly)
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

- Track events with properties directly from your backend
- Track events with properties through JavaScript using a Rack Middleware
- Set / increment user attributes directly from your backend
- Set / increment user attributes through JavaScript using a Rack Middleware

## Install

```ruby
  gem install mixpanel
```

### Rack Middleware

*Only needed if you want to track events via Javascript.*  This setup will allow your backend to have the client browser process the actual
requests over JavaScript rather than sending the request yourself.

If you are using Rails you can add this to your specific environment configuration file (located in config/environments/) or create a new
initializer for it:

```ruby
  config.middleware.use "Mixpanel::Middleware", "YOUR_MIXPANEL_API_TOKEN", options
```

Where **options** is a hash that accepts the following keys:

* **insert_mixpanel_scripts** : boolean

  *Default: true*

  By default the Mixpanel JavaScript API library scripts are inserted into the
  HTML. If you'd prefer to insert them yourself, set the
  insert_mixpanel_scripts flag to false.

* **insert_js_last** : boolean

  *Default: false*

  By default the scripts are inserted into the head of the HTML response. If you'd prefer the scripts to run after
  all rendering has completed, set the insert_js_last flag to true and they'll be added at the end of the body tag.
  This will work whether or not you opt for the aynchronous version of the API. However, this will have no effect
  when inserting JS into an AJAX response.

* **persist** : boolean

  *Default: false*

  If you would like, the Mixpanel gem may be configured to store its queue in a Rack session. This allows events
  to be stored through redirects, which can be helpful if you sign in and redirect but want to associate an event with that
  action. The Mixpanel gem will also remove duplicate events from your queue for information that should only be
  transmitted to the API once, such as `mixpanel.identify`, `mixpanel.name_tag`, `mixpanel.people.set`, and
  `mixpanel.register`.

  This allows you to use a before_filter to set these variables, redirect, and still have them only transmitted
  once.

  *To enable persistence*, you must set the flag twice: here when instantiating Middleware and again when you initialize the Mixpanel class.

* **config** : hash

  *Default: {}*

  You can also pass additional [Mixpanel configuration details](https://mixpanel.com/docs/integration-libraries/javascript-full-api#set_config).

## Usage

### Initialize Mixpanel

```ruby
  @mixpanel = Mixpanel::Tracker.new YOUR_MIXPANEL_API_TOKEN, options
```
Where **options** is a hash that accepts the following keys:

* **async** : boolean

  *Default: false*

  Built in async feature. Events are sent to a subprocess via a pipe and the sub process asynchronously send events to Mixpanel.
  This value can be overwritten on subsequent method calls.  I.e., this setting represents the default for your Mixpanel object,
  but each call can overwrite this default setting.

  This process uses a single thread to upload events, and may start dropping events if your application generates
  them at a very high rate.  While this is a simple way to have asynchronous interaction with Mixpanel, more robust solutions are
  available. Specifically, see the [Resque example](#how-to-track-events-using-resque-and-rails) below.

* **persist** : boolean

  *Default: false*

  This is used in connection with the [Rack Middleware section](#rack-middleware) above.  If you are not going to use Middleware
  to send requests to Mixpanel through JavaScript, you don't need to worry about this option.

  If you would like, the Mixpanel gem may be configured to store its queue in a Rack session. This allows events
  to be stored through redirects, which can be helpful if you sign in and redirect but want to associate an event with that
  action. The Mixpanel gem will also remove duplicate events from your queue for information that should only be
  transmitted to the API once, such as `mixpanel.identify`, `mixpanel.name_tag`, `mixpanel.people.set`, and
  `mixpanel.register`.

  This allows you to use a before_filter to set these variables, redirect, and still have them only transmitted
  once.

  *To enable persistence*, you must set the flag twice: when instantiating Middleware and here when you initialize
  the Mixpanel class.

* **api_key** : string

  *Default: nil*

  When using the [import functionality](#import-events), you must set an API key to go along with your token.  If not set when the
  class is instantiated, you will be required to send the api key in the options hash of the import method.

* **env** : hash

  *Default: {}*

  This is used by the gem to append information from your request environment to your Mixpanel request.  If you are calling this
  directly from a controller, simply passing in `request.env` will be sufficient.  However, as explained in the Resque example,
  your environment might choke if it tries to convert that hash to JSON (not to mention how large that hash can be).  You can just pass
  in a subset of the full environment:

  ```ruby
    env = {
      'REMOTE_ADDR' => request.env['REMOTE_ADDR'],
      'HTTP_X_FORWARDED_FOR' => request.env['HTTP_X_FORWARDED_FOR'],
      'rack.session' => request.env['rack.session'],
      'mixpanel_events' => request.env['mixpanel_events']
    }

    @mixpanel = Mixpanel::Tracker.new MIXPANEL_TOKEN, { :env => env }
  ```

  Basically, this information is being used to: set the default IP address associated with the request, and grab any session variables
  needed to run the Middleware stuff.

  Additional information contained in your environment (e.g., http_referer) can simply be sent in as attributes where appropriate
  for your use case.

### Track Events Directly

```ruby
  @mixpanel.track event_name, properties, options
```

**event_name** is a string denoting how you want this event to appear in your Mixpanel dashboard.

**properties** is a hash of properties to be associated with the event.  The keys in the properties can either be strings
or symbols.  If you send in a key that matches a [special property](https://mixpanel.com/docs/properties-or-segments/special-or-reserved-properties),
it will automatically be converted to the correct form (e.g., `{ :os => 'Mac' }` will be converted to `{ :$os => 'Mac' }`).

**options** is a hash that accepts the following keys:

* **async** : boolean

  *Default: the async value from when the class was instantiated*

* **api_key**: string

  *Default: the api_key value from when the class was instantiated*

* **url**: string

  *Default: `http://api.mixpanel.com/track/`*

  This can be used to proxy Mixpanel API requests.

* **test**: boolean

  *Default: false*

  Send data to a high priority rate limited queue to make testing easier

Example:

```ruby
@mixpanel.track 'Purchased credits', { :number => 5, 'First Time Buyer' => true }
```

If you would like to alias one distinct id to another, you can use the alias helper method:

```ruby
@mixpanel.alias 'Siddhartha', { distinct_id: previous_distinct_id }
```

### Pixel Based Event Tracking

```ruby
@mixpanel.tracking_pixel "Opened Email", { :distinct_id => "bob@email.com", :campaign => "Retarget" }
```

This allows to track events just by loading a pixel. It's usually useful for tracking opened emails.
You've got to specify your own `distinct_id` as it won't be able to retrieve it from cookies.

And you can use it in your views with an image_tag helper:
```ruby
image_tag @mixpanel.tracking_pixel("Opened Email", { :distinct_id => "bob@email.com", :campaign => "Retarget" }), :width => 1, :height => 1
```


Mixpanel docs: https://mixpanel.com/docs/api-documentation/pixel-based-event-tracking

### Redirect Based Event Tracking

```ruby
@mixpanel.redirect_url "Opened Email", 'http://www.example.com/' { :distinct_id => "bob@email.com", :campaign => "Retarget" }
```

This allows to track events just when a user clicks a link. It's usually useful for tracking opened emails.

### Import Events

```ruby
  @mixpanel.import event_name, properties, options
```

All of these options have the same meaning and same defaults as the [track method](#track-events-directly), except that the
default url is `http://api.mixpanel.com/import/`

Example:

```ruby
@mixpanel.import 'Purchased credits', { :number => 4, :time => 5.weeks.ago }, { :api_key => MY_API_KEY}
```

### Set Person Attributes Directly

```ruby
@mixpanel.set distinct_id_or_request_properties, properties, options
```

**distinct_id_or_request_properties** is whatever is used to identify the user to Mixpanel or a hash of
properties of the [engage event](https://mixpanel.com/docs/people-analytics/people-http-specification-insert-data) that exist
outside of the `$set`. Special properties will be automatically converted to the correct form (e.g., `{ :ip => '127.0.0.1' }` will be
converted to `{ :$ip => '127.0.0.1' }`

**properties** is a hash of properties to be set. The keys in the properties can either be strings
or symbols.  If you send in a key that matches a [special property](https://mixpanel.com/docs/people-analytics/special-properties),
it will automatically be converted to the correct form (e.g., `{ :first_name => 'Chris' }` will be converted to `{ :$first_name => 'Chris' }`).

**options** is a hash that accepts the following keys:

* **async**: boolean

  *Default: the async value from when the class was instantiated*

* **url**: string

  *Default: `http://api.mixpanel.com/engage/`*

  This can be used to proxy Mixpanel API requests

Example using `distinct_id` to identify the user:

```ruby
@mixpanel.set 'john-doe', { :age => 31, :email => 'john@doe.com' }
```

Example using request properties, telling mixpanel to [ignore the time](https://groups.google.com/forum/#!msg/mp-dev/Ao4f8D0IKms/6MVhQqFDzL8J):

```ruby
@mixpanel.set({ :distinct_id => 'john-doe', :ignore_time => true }, { :age => 31, :email => 'john@doe.com' })
```

### Increment Person Attributes Directly

```ruby
@mixpanel.increment distinct_id, properties, options
```

All of these options have the same meaning and same defaults as the [set method](#set-person-attributes-directly).  Note that according to Mixpanel's
docs, you cannot combine set and increment requests, and that is why they are split here.

Example:

```ruby
@mixpanel.increment 'john-doe', { :tokens => 5, :coins => -4 }
```

### Track Charges for Revenue Directly

```ruby
@mixpanel.track_charge distinct_id, amount, time, options
```

This allows you to use the Revenue tab in your mixpanel dashboard.

Example:

```ruby
@mixpanel.track_charge 'john-doe', 20.00
```

If you need to remove accidental charges for a person, you can use:

```ruby
@mixpanel.reset_charges distinct_id
```

### Append Events To Be Tracked With Javascript

*Note*: You should setup the [Rack Middleware](#rack-middleware).

```ruby
  @mixpanel.append_track event_name, properties
```

**event_name** and **properties** take the same form as [tracking the event directly](#track-events-directly).

Note that you must call mixpanel.identify() in conjunction with People requests like set(). If you make set() requests before
you identify the user, the change will not be immediately sent to Mixpanel. Mixpanel will wait for you to call identify() and then send the accumulated changes.

```ruby
  @mixpanel.append_identify distinct_id
  @mixpanel.append_set properties
```

### Execute Javascript API call

*Note*: You should setup the [Rack Middleware](#rack-middleware).

```ruby
  @mixpanel.append("register", {:some => "property"})
  @mixpanel.append("identify", "Unique Identifier")
```

### Give people real names with Javascript

*Note*: You should setup the [Rack Middleware](#rack-middleware).

This gives names to people tracked in the `Stream` view:

```ruby
  @mixpanel.append("name_tag", "John Doe")
```


### Prevent middleware from inserting code

*Note*: Only applies when [Rack Middleware](#rack-middleware) is setup.

Occasionally you may need to send a request for HTML that you don't want the middleware to alter. In your AJAX request include the header "SKIP_MIXPANEL_MIDDLEWARE" to prevent the mixpanel code from being inserted.

```javascript
  $.ajax("/path/to/api/endpoint", {
    headers: {"Skip-Mixpanel-Middleware": true}, // valid http headers don't allow underscores and get filtered by some webservers
    success: function(data) {
      // Process data here
    }
  });
```

Alternatively, you can add this line of code to your controller to temporarily disable the middleware:

 ```ruby
   Mixpanel::Middleware.skip_this_request
 ```

## Examples

### How to use it from Rails controllers?

In your ApplicationController class add a method to keep track of a Mixpanel instance.

```ruby
  def mixpanel
    @mixpanel ||= Mixpanel::Tracker.new YOUR_MIXPANEL_API_TOKEN, { :env => request.env }
  end
```

Then you can call against this method where it makes sense in your controller.  For example, in the users#create method:

```ruby
  def create
    @user = User.create( :name => 'Jane Doe', :gender => 'female', :mixpanel_identifer => 'asdf' )
    mixpanel.track 'User Created', {
      :gender => @user.gender,
      :distinct_id => @user.mixpanel_identifier,
      :time => @user.created_at
    } # Note that passing the time key overwrites the default value of Time.now

    mixpanel.set @user.mixpanel_identifer, { :gender => @user.gender, :created => @user.created_at, :name => @user.name }
  end
```

## How to track events using Resque and Rails

While there is built-in async functionality, other options are more robust (e.g., using a dedicated queue manager).  Below is an example of how this
might be done with [Resque](https://github.com/defunkt/resque), but the same concepts would apply no matter what queue manager you use.

```ruby
class MixpanelTrackEventJob
  @queue = :slow

  def self.mixpanel env
    Mixpanel::Tracker.new MIXPANEL_TOKEN, { :env => env }
  end

  def self.perform name, properties, env
    mixpanel(env).track name, properties
  end
end
```

```ruby
  class UsersController < ApplicationController
    def create
      @user = User.new(params[:user])

      if @user.save
        env = {
          'REMOTE_ADDR' => request.env['REMOTE_ADDR'],
          'HTTP_X_FORWARDED_FOR' => request.env['HTTP_X_FORWARDED_FOR'],
          'rack.session' => request.env['rack.session'],
          'mixpanel_events' => request.env['mixpanel_events']
        } # Trying to pass request.env to Resque is going to fail (it chokes when trying to conver it to JSON, but no worries...)

        Resque.enqueue MixpanelTrackEventJob, 'Sign up', { :invited => params[:invited] }, env

        redirect_to user_root_path
      else
        render :new
      end
    end
  end
```

## How to track events using Delayed Job and Rails
Below is an example of implementing async even tracking with Delayed Job

**Create a new worker**
```ruby
class MixpanelWorker < Struct.new(:name, :properties, :request_env)
  def perform
      if defined?(MIXPANEL_TOKEN)
        @mixpanel = Mixpanel::Tracker.new(MIXPANEL_TOKEN, { :env => request_env })
      else
        @mixpanel = DummyMixpanel.new
      end

      @mixpanel.track(name, properties)
  end
end
```

**Add the following to your Application controller**
```ruby
class ApplicationController < ActionController::Base
  before_filter :initialize_env

  private
  ##
  # Initialize env for mixpanel
  def initialize_env
    # Similar to the Resque problem above, we need to help DJ serialize the
    # request object.
    @request_env = {
      'REMOTE_ADDR' => request.env['REMOTE_ADDR'],
      'HTTP_X_FORWARDED_FOR' => request.env['HTTP_X_FORWARDED_FOR'],
      'rack.session' => request.env['rack.session'].to_hash,
      'mixpanel_events' => request.env['mixpanel_events']
    }
  end
```
**You can optionally create a nice model wrapper to tidy things up**
```ruby
#app/models/mix_panel.rb
class MixPanel
  def self.track(name, properties, env)
    # Notice we are using the 'mixpanel' queue
		Delayed::Job.enqueue MixpanelWorker.new(name, properties, env), queue: 'mixpanel'
	end
end
```
**Sample Usage**
```ruby
MixPanel.track("Front Page Load", {
                url_type: short_url.uid_type,
                page_name: short_url.page.name,
                distinct_id: @client_uid }, @request_env)
```

## Supported Ruby Platforms

- 1.8.7 [Not supported anymore]
- 1.9.2
- 1.9.3
- 2.0.0
- JRuby 1.8 Mode
- JRuby 1.9 Mode

## Deprecation Notes

  * 4.0.0
    People API #append_people_identify => #append_identify

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
* [Sylvain Niles](https://github.com/sylvainsf)
* [GBH](https://github.com/GBH)
* [Goalee](https://github.com/Goalee)
* [Ahmed Belal](https://github.com/AhmedBelal)
* [Esteban Pastorino](https://github.com/kitop)
* [Jeffrey Chu](https://github.com/jochu)
* [Jon Pospischil] (https://github.com/pospischil)
* [Tom Brown] (https://github.com/nottombrown)
* [Murilo Pereira] (https://github.com/mpereira)
* [Marko Vasiljevic] (https://github.com/marmarko)
* [Joel] (https://github.com/jclay)
* [adimichele] (https://github.com/adimichele)
* [Francis Gulotta] (https://github.com/reconbot)
