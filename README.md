Rainbow Lollipop
================

Rainbow Lollipop is an experimental browser that concentrates on exploring,
developing and refining new ways for users to interact with the worldwide web.

![Screenshot of Rainbow Lollipop](http://rainbow-lollipop.de/img/screenshot.png)

Rainbow Lollipop is written in [Vala](https://live.gnome.org/Vala) and builds
on the following awesome libraries:

  * [Gtk](http://gtk.org)
  * [Clutter](http://clutter-project.org)
  * [Webkit2Gtk](http://webkitgtk.org)
  * [ØMQ](http://zeromq.org)
  * [Sqlite](https://sqlite.org)

Philosophy
----------

Rainbow Lollipop is the browser of the future. Drop all chains that hold back your
imagination. Ask yourself: If you were to create the first
browser today with all the knowledge you have gained about browsing the web in the last
twenty-five years, how would you have done it? Start from scratch. Rethink browsing the
web.

I started this project because i've seen that browsing UIs haven't changed significantly
in 15 years since the invention of the modern browsing tab in 1997 by Adam Stiles despite
the fact that tabs don't really represent how we use the web today. I came up with a new
concept which is called Track and needed to prototype it. After some experimenting around,
it came to me, that there is much more to do. A browser for the time we live in should
come with sane security standards. Why is HTTPSEverywhere still a plugin everywhere? Why
are adblockers still plugins in a web which is contaminated with advertisement everywhere
you go? For the end-users sake, such features should be delivered ootb.
And there is more that we can do.

Rainbow lollipop is a sandbox to try out new things, which the big browsers are too afraid
of to try out, because they fear to lose their userbase. You've probably had a great
idea for your perfect browser, too. If you have any idea (no matter how strange it may sound),
propose it to this project. I want the world of browsers to move forward. And i want to do
it together with all of you.

Rethink browsing, everytime you browse.

Contributions
-------------

As implied above, contributions are very welcome. If you can code, there is much to do:
Code the smaller and bigger features, help fixing bugs, help translating, create
documentation and so on. Or use rainbow lollipop as a platform to bring your big next
browsing-related idea to life.
Just send a pullrequest and/or communicate with the rest on the [Mailing List](http://lists.rainbow-lollipop.de) or on #rainbow-lollipop on irc.freenode.net.

Roadmap
-------

  * [x] Track based browsing.
    Tracks are a new UI concept that replaces the currently widely known concept of Tabs

  * [x] URL-Autocompletion.
    There is still some work to do to enhance UX

  * [ ] Integration of HTTPSEverywhere-like functionality.

  * [ ] Integration of Adblocking

  * [ ] Script-Blocking

  * [ ] Deepweb Integration

  * And two more pretty features that i am not really ready to talk about yet.

Building the Project
--------------------

To compile the project, do the following steps:

Install the dependencies (debian)

```
 # apt-get install valac-0.26 libgtk-3-dev libgee-0.8-dev libclutter-1.0-dev libzmq-dev libwebkit2gtk-4.0-dev libclutter-gtk-1.0-dev libzmq-dev libsqlite3-dev
```

Note: On Arch Linux, you will have to specify that you want libzmq2 which is available as a package zeromq2 via yaourt.

Build the program

```
 $ cmake .
 $ make
 # make install/local
```

Please note, that without the make install command, the program will not work properly at the moment.
This inconvenience comes from a hardcoded library path at the moment. I am sorry for that and i will
fix it.
