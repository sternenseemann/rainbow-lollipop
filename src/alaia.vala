using Gtk;
using Gdk;
using GtkClutter;
using Clutter;
using WebKit;

namespace alaia {
    class TrackList : Clutter.Rectangle {
        public TrackList(Clutter.Actor stage) {
            this.add_constraint(
                new Clutter.BindConstraint(stage, Clutter.BindCoordinate.SIZE,0)
            );
            this.color = Clutter.Color.from_string("#121212");
            this.set_reactive(true);
            this.set_opacity(0x00);
            this.button_press_event.connect(do_button_press_event);
            this.key_press_event.connect(do_key_press_event);
            stage.add_child(this);
        }

        public bool do_key_press_event(Clutter.KeyEvent e) {
            stdout.printf("buttonpressed\n");
            stdout.printf("%ui\n",e.keyval);
            return true;
        }
        [CCode (instance_pos = -1)]
        public bool do_button_press_event(Clutter.ButtonEvent e) {
            stdout.printf("trcklist\n");
            return true;
        }
        
        public void emerge() {
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

        public bool do_test_event(Gdk.EventButton e) {
            stdout.printf("foobar\n");
            return true;
        }

        public Application()  {
            GLib.Object(
                application_id : "de.grindhold.alaia",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE,
                register_session : true
            );
            
            this.web = new WebKit.WebView();
            this.web.button_press_event.connect(do_test_event);
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

            this.tracklist = new TrackList(stage);

            this.win.show_all();
            this.web.open("http://spurdospaer.de");
            Gtk.main();
        }
        
        public void do_delete() {
            Gtk.main_quit();
        }

        public bool do_button_press_event(Clutter.ButtonEvent e) {
            stdout.printf("foobar\n");
            return true;
        }

        public bool  do_key_press_event(Gdk.EventKey e) {
            stdout.printf("%u\n",e.keyval);
            stdout.printf("%s\n",e.str);
            switch (this.state) {
                case AppState.NORMAL:
                    switch (e.keyval) {
                        case Gdk.Key.Tab:
                            this.tracklist.emerge();
                            this.state = AppState.TRACKLIST;
                            break;
                        default:
                            return true;
                    }
                    break;
                case AppState.TRACKLIST:
                    switch (e.keyval) {
                        case Gdk.Key.Tab:
                            this.tracklist.disappear();
                            this.state = AppState.NORMAL;
                            break;
                        default:
                            return true;
                    }
                    break;
            }
            return true;
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
