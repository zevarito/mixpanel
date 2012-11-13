November 2012
-------------

* Pixel Based Event Tracking (Esteban Pastorino)

October 2012
--------------

* API Changes, please take a look at README file.
* Add support for mixpanel.people.identify (Ahmed Belal)
* Engage endpoint added. (GBH)
* Code revision (Chris Sturgill)

September 2012
--------------

* Added support for Import API (Sylvain Niles)
* Ability to skip Mixpanel Middleware through HTTP custom header
* Use mixpanel script version 2.1 (Travis Pew)

August 2012
-------------
* Added Javascript API 2 support (Jamie Quint)
* Add persistence feature (Ryan Schmukler)
* Deprecate: Mixpanel.new
* Use new JS CDN hosted (Alvaro Gil)

January 2012
-------------
* Ability to proxy Mixpanel calls (Mark Cheverton)

December 2011
-------------
* Add HTTP_X_FORWARDED_FOR to obtain ip addresses, Heroku thing. (Alvaro Gil)

November 2011
-------------

* Fix content length update, IE. Send file bug (Brad Wilson)

October 2011
--------------
* Ability to insert JS scripts at the bottom of Body element (James Ferguson)

September 2011
--------------

* Updated middleware with latest mixpanel javascript (eddiesiegel)
* Allow overriding of token, time, and ip address (Joe Van Dyk)
* Spelling correction (jellybob)

June 2011
---------

* Refactor Gem to live in Mixpanel::Tracker and avoid conflicts with other gems.

January 2011
------------

* Fix how the interpreter is called for asynchronous call support. (jakemack)
* Added optional asynchrony usage built in. (Logan Bowers)

Novemeber 2010
--------------

* Bug fixes. (Nathan Baxter)
* Allow api calls other than track through the javascript API. (Nathan Baxter)
* Added support for mixpanel's asynchronous javascript mechanism. (Nathan Baxter)
* Add support for large ajax responses in Rails. (Jake Mallory)
