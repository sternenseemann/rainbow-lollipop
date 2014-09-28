using Gtk;
using Gdk;
using GtkClutter;
using Clutter;
using WebKit;
using Gee;

namespace alaia {
    class TrackColorSource : GLib.Object {
        private static Gee.ArrayList<string> colors;
        private static int state = 0;
        private static bool initialized = false;
        
        public static void init() {
            if (!TrackColorSource.initialized) {
                stdout.printf("init");
                TrackColorSource.colors = new Gee.ArrayList<string>();
                TrackColorSource.colors.add("#f00");
                TrackColorSource.colors.add("#ff0");
                TrackColorSource.colors.add("#0f0");
                TrackColorSource.colors.add("#0ff");
                TrackColorSource.colors.add("#00f");
                TrackColorSource.colors.add("#f0f");
                TrackColorSource.initialized = true;
            }
        }

        public static Clutter.Color get_color() {
            TrackColorSource.init();
            var color = TrackColorSource.colors.get(TrackColorSource.state);
            if (++TrackColorSource.state == TrackColorSource.colors.size) {
                TrackColorSource.state = 0;
            }
            stdout.printf("colort: %s\n", color);
            return Clutter.Color.from_string(color);
        }
    }   

    class Track : Clutter.Rectangle {
        private Clutter.Actor stage;
        public Track(Clutter.Actor tl) {
            this.add_constraint(
                new Clutter.BindConstraint(tl, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.color = TrackColorSource.get_color();
            this.height = 150;
            this.y = 150;
            this.opacity = 0xEE;
            this.visible = true;
            this.transitions_completed.connect(do_transitions_completed);
            tl.add_child(this); 
        }
        private void do_transitions_completed() {
            if (this.opacity == 0x00) {
                this.visible = false;
            }
        }
        public void emerge() {
            this.visible = true;
            this.save_easing_state();
            this.opacity = 0xE0;
            this.restore_easing_state();
        }
        public void disappear() {
            this.save_easing_state();
            this.opacity = 0x00;
            this.restore_easing_state();
        }
    }

    class EmptyTrack : Track {
        private Gtk.Entry url_entry;
        private Gtk.Button enter_button;
        private Gtk.HBox hbox;
        private GtkClutter.Actor actor; 
        private TrackList tracklist;

        public EmptyTrack(Clutter.Actor stage, TrackList tl) {
            base(stage);
            this.tracklist = tl;
            this.url_entry = new Gtk.Entry();
            this.enter_button = new Gtk.Button.with_label("Go");
            this.hbox = new Gtk.HBox(false, 5);
            this.color = Clutter.Color.from_string("#555");
            this.hbox.pack_start(this.url_entry,true);
            this.hbox.pack_start(this.enter_button,false);
            this.url_entry.activate.connect(do_activate);
            this.actor = new GtkClutter.Actor.with_contents(this.hbox);
            
            this.actor.add_constraint(
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.actor.add_constraint(
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.Y, 62)  
            );
            
            this.actor.height=25;
            //this.actor.y = 150;
            this.actor.visible = true;
            this.actor.transitions_completed.connect(do_transitions_completed);
            this.actor.show_all();

            stage.add_child(this.actor);
            
        }

        private void do_activate() {
            this.tracklist.add_track(this.url_entry.get_text());
        }

        private void do_transitions_completed() {
            if (this.actor.opacity == 0x00) {
                this.actor.visible=false;
            }
        }

        public void emerge() {
            base.emerge();
            this.actor.visible = true;
            this.actor.save_easing_state();
            this.actor.opacity = 0xE0;
            this.actor.restore_easing_state();
        }

        public void disappear() {
            base.disappear();
            this.actor.save_easing_state();
            this.actor.opacity = 0x00;
            this.actor.restore_easing_state();
        }
        
    }

    class HistoryTrack : Track {
        private WebKit.WebView web;
        private string url;

        public HistoryTrack(Clutter.Actor stage, string url, WebView web) {
            base(stage);
            this.web = web;
            this.web.open(url);
            this.url = url;
        }
    }

    class TrackList : Clutter.Rectangle {
        private Gee.ArrayList<Track> tracks;
        private Clutter.Actor stage;
        private WebKit.WebView web;

        public TrackList(Clutter.Actor stage, WebView web) {
            this.web = web;
            this.tracks = new Gee.ArrayList<Track>();
            this.stage = stage;
            
            this.add_constraint(
                new Clutter.BindConstraint(stage, Clutter.BindCoordinate.SIZE,0)
            );
            this.color = Clutter.Color.from_string("#121212");
            this.reactive=true;
            this.opacity = 0x00;
            this.visible = false;
            this.transitions_completed.connect(do_transitions_completed);
            stage.add_child(this);
            this.add_empty_track();
        }

        public void add_track(string url) {
            this.tracks.insert(this.tracks.size-1, new HistoryTrack(this.stage, url, this.web));
        }

        private void add_empty_track() {
            this.tracks.insert(this.tracks.size,new EmptyTrack(this.stage, this));
        }

        /*public bool do_key_press_event(Clutter.KeyEvent e) {
            stdout.printf("buttonpressed\n");
            stdout.printf("%ui\n",e.keyval);
            return true;
        }*/
    
        /*[CCode (instance_pos = -1)]
        public bool do_button_press_event(Clutter.ButtonEvent e) {
            stdout.printf("trcklist\n");
            return true;
        }*/

        private void do_transitions_completed() {
            if (this.opacity == 0x00) {
                this.visible = false;
            }
        }
        
        public void emerge() {
            foreach (Track t in this.tracks){
                try {
                    var et = (EmptyTrack)t;
                    et.emerge();
                } catch {
                    t.emerge();
                }
            }
            this.visible = true;
            this.save_easing_state();
            this.opacity = 0xE0;
            this.restore_easing_state();
        }

        public void disappear() {
            foreach (Track t in this.tracks){
                try {
                    var et = (EmptyTrack)t;
                    et.disappear();
                } catch {
                    t.disappear();
                }
            }
            this.save_easing_state();
            this.opacity = 0x00;
            this.restore_easing_state();
        }
    }

    enum AppState {
        NORMAL,
        TRACKLIST
    }

    class Application : Gtk.Application {
        private GtkClutter.Window win;
        private WebKit.WebView web;
        private GtkClutter.Actor webact;

        private TrackList tracklist;
        
        private AppState state;

        public Application()  {
            GLib.Object(
                application_id : "de.grindhold.alaia",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE,
                register_session : true
            );
            
            this.web = new WebKit.WebView();
            this.webact = new GtkClutter.Actor.with_contents(this.web);

            this.win = new GtkClutter.Window();
            this.win.set_title("alaia");
            this.win.key_press_event.connect(do_key_press_event);
            this.win.destroy.connect(do_delete);

            var stage = this.win.get_stage();
            this.webact.add_constraint(new Clutter.BindConstraint(
                stage, Clutter.BindCoordinate.SIZE, 0)
            );
            stage.add_child(this.webact);
            stage.set_reactive(true);
            //stage.key_press_event.connect(do_key_press_event);
            stage.button_press_event.connect(do_button_press_event);

            this.tracklist = new TrackList(stage, this.web);

            this.win.show_all();
            this.web.open("https://blog.fefe.de");
            Gtk.main();
        }
        
        public void do_delete() {
            Gtk.main_quit();
        }

        public bool do_button_press_event(Clutter.ButtonEvent e) {
            stdout.printf("foobar\n");
            return true;
        }

        public bool do_key_press_event(Gdk.EventKey e) {
            stdout.printf("%u\n",e.keyval);
            stdout.printf("%s\n",e.str);
            switch (this.state) {
                case AppState.NORMAL:
                    switch (e.keyval) {
                        case Gdk.Key.Tab:
                            this.tracklist.emerge();
                            this.state = AppState.TRACKLIST;
                            return true;
                        default:
                            return false;
                    }
                case AppState.TRACKLIST:
                    switch (e.keyval) {
                        case Gdk.Key.Tab:
                            this.tracklist.disappear();
                            this.state = AppState.NORMAL;
                            return true;
                        default:
                            return false;
                    }
            }
            return false;
        }
        
        public static int main(string[] args) {
            if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS){
                stdout.printf("Could not initialize GtkClutter");
            }
            new Application();
            return 0;
        }
    }
}
