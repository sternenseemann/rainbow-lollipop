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

    class ContextMenu : Gtk.Menu {
        private Gtk.ImageMenuItem new_track_from_node;
        private Gtk.ImageMenuItem delete_branch;
        private Gtk.ImageMenuItem delete_track;
        private Node? node;
        private Track? track;
        
        public ContextMenu () {
            this.new_track_from_node = new Gtk.ImageMenuItem.with_label("New Track from Branch");
            //this.new_track_from_node.allways_show_image = true;
            this.new_track_from_node.set_image(
                new Gtk.Image.from_stock(Gtk.Stock.JUMP_TO, Gtk.IconSize.MENU)
            );
            this.new_track_from_node.activate.connect(do_new_track_from_node);
            this.add(this.new_track_from_node);
            this.delete_branch = new Gtk.ImageMenuItem.with_label("Close Branch");
            //this.delete_branch.allways_show_image = true;
            this.delete_branch.set_image(
                new Gtk.Image.from_stock(Gtk.Stock.DELETE, Gtk.IconSize.MENU)
            );
            this.delete_branch.activate.connect(do_delete_branch);
            this.add(this.delete_branch);
            this.add(new Gtk.SeparatorMenuItem());
            this.delete_track = new Gtk.ImageMenuItem.with_label("Close Track");
            //this.delete_track.allways_show_image = true;
            this.delete_track.set_image(
                new Gtk.Image.from_stock(Gtk.Stock.CLOSE, Gtk.IconSize.MENU)
            );
            this.delete_track.activate.connect(do_delete_track);
            this.add(this.delete_track);

            this.show_all();
        }

        public void set_context(Track? track, Node? node) {
            this.track = track;
            this.node = node;
            
            this.delete_track.visible = this.track != null;
            this.new_track_from_node.visible = this.node != null;
            this.delete_branch.visible = this.node != null;
        }

        public void do_new_track_from_node(Gtk.MenuItem m) {
            if (this.node != null)
                this.node.move_to_new_track();
        }
        public void do_delete_branch(Gtk.MenuItem m) {
            if (this.node  != null)
                this.node.delete_node();
        }
        public void do_delete_track(Gtk.MenuItem m) {
            if (this.track != null)
                this.track.delete_track();
        }
    }

    class Application : Gtk.Application {
        private static Application app;

        private GtkClutter.Window win;
        private ContextMenu context;
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

            //Load config

            Config.load();
            
            this._state = AppState.TRACKLIST;

            this.web = new WebKit.WebView();
            this.web.load_committed.connect(do_load_committed);
            this.webact = new GtkClutter.Actor.with_contents(this.web);

            this.win = new GtkClutter.Window();
            this.win.set_title("alaia");
            this.win.key_press_event.connect(do_key_press_event);
            this.win.button_press_event.connect(do_button_press_event);
            this.win.destroy.connect(do_delete);

            this.context = new ContextMenu();

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

        public bool do_button_press_event(Gdk.EventButton e) {
            if (e.button == Gdk.BUTTON_SECONDARY) {
                Track track = this.tracklist.get_track_on_position(e.x,e.y);
                Node node = null;
                if (track != null) {
                    node = track.get_node_on_position(e.x,e.y);
                }
                this.context.set_context(track,node);
                this.context.popup(null,null,null,e.button, e.time);
            }
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
