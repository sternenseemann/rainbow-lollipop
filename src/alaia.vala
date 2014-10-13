using Gtk;
using Gdk;
using GtkClutter;
using Clutter;
using WebKit;
using Gee;

namespace alaia {
    enum AppState {
        NORMAL,
        TRACKLIST
    }

    class Application : Gtk.Application {
        private static Application app;

        private GtkClutter.Window win;
        private WebKit.WebView web;
        private GtkClutter.Actor webact;

        private TrackList tracklist;
        
        private AppState _state;

        public AppState state {
            get {
                return this._state;
            }
        }

        public Application()  {
            GLib.Object(
                application_id : "de.grindhold.alaia",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE,
                register_session : true
            );
            
            this._state = AppState.TRACKLIST;

            this.web = new WebKit.WebView();
            this.web.load_committed.connect(do_load_committed);
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
            stage.reactive = true;

            this.tracklist = new TrackList(stage, this.web);
            stage.add_child(this.tracklist);

            this.win.show_all();
            this.tracklist.emerge();
        }

        public void do_load_committed(WebFrame wf) {
            this.tracklist.log_call(wf);
        }
        
        public void do_delete() {
            Gtk.main_quit();
        }

        public bool do_button_press_event(Clutter.ButtonEvent e) {
            stdout.printf("foobar\n");
            return false;
        }

        public bool do_key_press_event(Gdk.EventKey e) {
            switch (this._state) {
                case AppState.NORMAL:
                    switch (e.keyval) {
                        case Gdk.Key.Tab:
                            this.tracklist.emerge();
                            this._state = AppState.TRACKLIST;
                            return true;
                        default:
                            return false;
                    }
                case AppState.TRACKLIST:
                    switch (e.keyval) {
                        case Gdk.Key.Tab:
                            this.tracklist.disappear();
                            this._state = AppState.NORMAL;
                            return true;
                        default:
                            return false;
                    }
            }
            return false;
        }

        public static Application S() {
            return Application.app;
        }
        
        public static int main(string[] args) {
            if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS){
                stdout.printf("Could not initialize GtkClutter");
            }
            Application.app = new Application();
            Gtk.main();
            return 0;
        }
    }
}
