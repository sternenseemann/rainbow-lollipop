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
            this.new_track_from_node.set_image(
                new Gtk.Image.from_icon_name("go-jump", Gtk.IconSize.MENU)
            );
            this.new_track_from_node.activate.connect(do_new_track_from_node);
            this.add(this.new_track_from_node);
            this.delete_branch = new Gtk.ImageMenuItem.with_label("Close Branch");
            this.delete_branch.set_image(
                new Gtk.Image.from_icon_name("edit-delete", Gtk.IconSize.MENU)
            );
            this.delete_branch.activate.connect(do_delete_branch);
            this.add(this.delete_branch);
            this.add(new Gtk.SeparatorMenuItem());
            this.delete_track = new Gtk.ImageMenuItem.with_label("Close Track");
            this.delete_track.set_image(
                new Gtk.Image.from_icon_name("window-close", Gtk.IconSize.MENU)
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
        private ContextMenu _context;
        public ContextMenu context {get{return _context;}}
        private Gee.HashMap<HistoryTrack,WebKit.WebView> webviews;
        private Gtk.Notebook webviews_container;
        private GtkClutter.Actor webact;

        private TrackList tracklist;
        private TrackListBackground tracklist_background;
        
        private AppState _state;

        public AppState state {
            get {
                return this._state;
            }
        }

        private Application()  {
            GLib.Object(
                application_id : "de.grindhold.alaia",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE,
                register_session : true
            );

            //Load config

            Config.load();
            
            this._state = AppState.TRACKLIST;

            this.webviews = new Gee.HashMap<HistoryTrack, WebKit.WebView>();
            this.webviews_container = new Gtk.Notebook();
            this.webviews_container.show_tabs = false;
            this.webact = new GtkClutter.Actor.with_contents(this.webviews_container);

            this.win = new GtkClutter.Window();
            this.win.set_title("alaia");
            this.win.maximize();
            this.win.key_press_event.connect(do_key_press_event);
            this.win.destroy.connect(do_delete);

            this._context = new ContextMenu();

            var stage = this.win.get_stage();
            this.webact.add_constraint(new Clutter.BindConstraint(
                stage, Clutter.BindCoordinate.SIZE, 0)
            );
            stage.add_child(this.webact);
            stage.reactive = true;

            this.tracklist_background = new TrackListBackground(stage);
            stage.add_child(this.tracklist_background);

            this.tracklist = (TrackList)this.tracklist_background.get_first_child();
            this.win.show_all();
            this.tracklist_background.emerge();
        }

        //TODO: exchange Gtk.Action for GLib.Simpleaction as soon as webkitgtk is ready for it
        public bool do_web_context_menu(WebKit.ContextMenu cm, Gdk.Event e, WebKit.HitTestResult htr){
            var w = this.webviews_container.get_nth_page(this.webviews_container.page) as WebView;
            WebKit.ContextMenuItem mi;
            //GLib.SimpleAction a;
            Gtk.Action a;
            cm.remove_all();
            if (w.can_go_back()) {
                //a = new GLib.SimpleAction("navigate-back",null);
                a = new Gtk.Action("nanvigate-back", "Go Back", null, null);
                a.activate.connect(()=>{
                    this.tracklist.current_track.go_back();
                });
                cm.append(new WebKit.ContextMenuItem(a as Gtk.Action));
            }
            if (w.can_go_forward()) {
                //a = new GLib.SimpleAction("navigate-forward",null);
                a = new Gtk.Action("nanvigate-forward", "Go Forward", null, null);
                a.activate.connect(()=>{
                    this.tracklist.current_track.go_forward();
                });
                cm.append(new WebKit.ContextMenuItem(a as Gtk.Action));
            }
            return false;
        }

        public WebKit.WebView get_web_view(HistoryTrack t) {
            if (!this.webviews.has_key(t)) {
                var w = new WebKit.WebView();
                w.web_context.set_favicon_database_directory("/tmp/alaia_favicons");
                w.context_menu.connect(do_web_context_menu);
                this.webviews.set(t,w);
                this.webviews_container.append_page(w);
            }
            return this.webviews.get(t);
        }

        public void destroy_web_view(HistoryTrack t) {
            if (this.webviews.has_key(t))
                this.webviews[t].destroy();
        }
    
        public void show_web_view(HistoryTrack t) {
            if (this.webviews.has_key(t)){
                var page = this.webviews_container.page_num(this.webviews[t]);
                this.webviews_container.set_current_page(page);
                this.webviews_container.show_all();
            }
        }
        
        public void do_delete() {
            Gtk.main_quit();
        }

        public bool do_key_press_event(Gdk.EventKey e) {
            switch (this._state) {
                case AppState.NORMAL:
                    switch (e.keyval) {
                        case Gdk.Key.Tab:
                            this.tracklist_background.emerge();
                            this._state = AppState.TRACKLIST;
                            return true;
                        default:
                            return false;
                    }
                case AppState.TRACKLIST:
                    switch (e.keyval) {
                        case Gdk.Key.Tab:
                            this.tracklist_background.disappear();
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

        public static string get_config_filename(string name) {
            File f = File.new_for_path(GLib.Environment.get_user_config_dir()+Config.C+name);
            if (f.query_exists())
                return f.get_path();
            foreach (string dir in GLib.Environment.get_system_config_dirs()) {
                f = File.new_for_path(dir+Config.C+name);
                if (f.query_exists())
                    return f.get_path();
            }
            f = File.new_for_path("/etc"+Config.C+name);
            if (f.query_exists())
                return f.get_path();
#if DEBUG
            return "cfg/"+name;
#else
            return "";
#endif
        }

        public static string get_data_filename(string name) {
            File f = File.new_for_path(GLib.Environment.get_user_data_dir()+Config.C+name);
            if (f.query_exists())
                return f.get_path();
            foreach (string dir in GLib.Environment.get_system_data_dirs()) {
                f = File.new_for_path(dir+Config.C+name);
                if (f.query_exists())
                    return f.get_path();
            }
#if DEBUG
            return "data/"+name;
#else
            return "";
#endif
        }
    }
}
