/********************************************************************
# Copyright 2014 Daniel 'grindhold' Brendle
#
# This file is part of Rainbow Lollipop.
#
# Rainbow Lollipop is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later
# version.
#
# Rainbow Lollipop is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with Rainbow Lollipop.
# If not, see http://www.gnu.org/licenses/.
*********************************************************************/

using Gtk;
using Gdk;
using GtkClutter;
using Clutter;
using WebKit;
using Gee;


namespace RainbowLollipop {
    const string GETTEXT_PACKAGE = "rainbow-lollipop";

    /**
     * Counts how often the unichar x occurs in the string s
     */
    public uint count_char(string s, unichar x) {
        uint r = 0;
        for (int i = 0; i < s.char_count(); i++) {
            if (s.get_char(i) == x)
                r++;
        }
        return r;
    }

    /**
     * Extended Version of WebKit's WebView which is able to store
     * a reference to a HistoryTrack along with it and offers methods
     * to communicate with the web-extension-process of this view.
     */
    public class TrackWebView : WebKit.WebView {
        /**
         * Stores a reference to the HistoryTrack that is associated with
         * this WebView
         */
        public HistoryTrack track{ get;set; }
        private SearchWidget search;
        private bool searchstate;

        /**
         *
         */
        public TrackWebView(Clutter.Actor webactor) {
            this.search = new SearchWidget(webactor, this.get_find_controller());
            webactor.add_child(this.search);
        }

        /**
         * Asks The web-extension-process whether this webview currently
         * needs input from the keyboard e.g. to fill content into a
         * HTML form-element.
         */
        public async void needs_direct_input(IPCCallback cb, Gdk.EventKey e) {
            ZMQVent.needs_direct_input(this, cb, e);
        }

        /**
         * Returns true if the searchoverlay is currently active for this webview
         */
        public bool is_search_active() {
            return this.searchstate;
        }

        /**
         * Shows up the search dialog
         */
        public void start_search(string search_string="") {
            this.search.visible = this.searchstate = true;
            this.search.set_search_string(search_string);
        }

        /**
         * Returns the current search string
         */
        public string get_search_string() {
            return this.search.get_search_string();
        }

        /**
         * Shuts down the search overlay
         */
        public void stop_search() {
            this.searchstate = false;
        }

        /**
         * Hides the search overlay
         */
        public void hide_search() {
            this.search.visible = false;
        }

        /**
         * Shows the search overlay if there is currently a search going on
         */
        public void restore_search() {
            this.search.visible = this.searchstate;
        }
    }

    /**
     * The main Application Class
     */
    class Application : Gtk.Application {
        private const string SESSION_FILE = "session.json";
        private static Application app;

        private GtkClutter.Window win;
        private ContextMenu _context;
        public ContextMenu context {get{return _context;}}

        /**
         * Holds references to all Webviews that are currently being used by
         * Tracks
         */
        private Gee.HashMap<HistoryTrack,TrackWebView> webviews;
        /**
         * Organizes the webviews.
         */
        private Gtk.Notebook webviews_container;
        /**
         * Wrapper to embed webviews into a clutter environment
         */
        private GtkClutter.Actor webact;

        /**
         * Holds a reference to the tracklist
         */
        public TrackList tracklist {get;set;}
        private TrackListBackground tracklist_background;

        private RestoreSessionDialog sessiondialog;

        private ConfigDialog configdialog;

        /**
         * The state the application is currently in.
         * Application states are enumerated by the enum AppState
         */
        private IApplicationState _state;
        public IApplicationState state {
            get {
                return this._state;
            }
            set {
                if (this._state != null)
                    this._state.leave();
                this._state = value;
                this._state.enter();
            }
        }

        /**
         * Initializes the translations of this program
         * TODO: The following section is a mess:
         * There are three possible directories where the language-files (*.mo)
         * could reside in:
         *     /usr/share/locale
         *     /usr/local/share/locale
         *     ./data/locale
         * because the gnu gettext-conform paths have the following structure
         *     <localedir>/<language>/LC_MESSAGES/rainbow-lollipop.mo
         * i would have to know the current locale at runtime in order to check for
         * the languagefile to exist.
         * Instead i will check statically for the english languagefile at the path
         *     <localedir>/en/LC_MESSAGES/rainbow-lollipop.mo
         * because i can assume that if one language file got installed, every other
         * languagefile got installed in the same folder structure, too.
         * In the future, specific tests and a better solution would be nice.
         */
        private void init_locale() {
            Intl.setlocale(LocaleCategory.MESSAGES, "");
            Intl.textdomain(GETTEXT_PACKAGE);
            Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
            bool found_locale = false;
            foreach (string dir in GLib.Environment.get_system_data_dirs()) {
                found_locale = FileUtils.test(
                                    dir+"locale/en/LC_MESSAGES/rainbow-lollipop.mo",
                                    FileTest.EXISTS
                );
                if (found_locale) {
                    Intl.bindtextdomain(GETTEXT_PACKAGE, dir+"locale");
                    break;
                }
            }
            if (!found_locale)
                Intl.bindtextdomain(GETTEXT_PACKAGE, "./data/locale");
        }

        /**
         * Application Constructor
         */
        private Application()  {
            GLib.Object(
                application_id : "de.grindhold.alaia",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE,
                register_session : true
            );
        }

        private static void* init_httpseverywhere() {
            HTTPSEverywhere.init();
            return null;
        }

        /**
         * Initializes the window and browser
         */
        private void initialize() {
            // Internationalization
            init_locale();

            // Load config
            Config.load();

            // Initialize the IPC-Classes
            ZMQVent.init();
            ZMQSink.init();

            // Initialize HTTPSEverywhere
            try {
                new Thread<void*>.try(null,Application.init_httpseverywhere);
            } catch (GLib.Error e) {
                stdout.printf(_("HTTPSEverywhere initialization thread failed\n"));
            }
            
            // Initialize stuff to display WebViews
            this.webviews = new Gee.HashMap<HistoryTrack, TrackWebView>();
            this.webviews_container = new Gtk.Notebook();
            this.webviews_container.show_tabs = false;
            this.webact = new GtkClutter.Actor.with_contents(this.webviews_container);

            NormalState.init(this.webact);

            // Initialize the main window
            this.win = new GtkClutter.Window();
            this.win.set_title("Rainbow Lollipop");
            this.win.maximize();
            this.win.icon_name="rainbow-lollipop";
            this.win.key_press_event.connect(preprocess_key_press_event);
            this.win.destroy.connect(do_delete);

            this._context = new ContextMenu();

            // Bind webview-stuff to mainwindow
            var stage = this.win.get_stage();
            this.webact.add_constraint(new Clutter.BindConstraint(
                stage, Clutter.BindCoordinate.SIZE, 0)
            );
            stage.add_child(this.webact);
            stage.reactive = true; // Make sure, stage emits key-presses and mouse-clicks.

            // Create and initialize modals
            this.tracklist_background = new TrackListBackground(stage);
            stage.add_child(this.tracklist_background);
            this.tracklist = (TrackList)this.tracklist_background.get_first_child();
            TracklistState.init(this.tracklist_background);

            this.sessiondialog = new RestoreSessionDialog(stage);
            stage.add_child(this.sessiondialog);
            SessiondialogState.init(this.sessiondialog);

            this.configdialog = new ConfigDialog(stage);
            stage.add_child(this.configdialog);
            ConfigState.init(this.configdialog);

            // Initialize Tracklist


            // Show everything that is needed on screen.
            this.win.show_all();
            this.sessiondialog.disappear();
            this.tracklist_background.disappear();

            if (this.old_session_available())
                this.state = SessiondialogState.S();
            else
                this.state = TracklistState.S();

            // Initialize webkit environment
            WebKit.WebContext.get_default().set_process_model(
                WebKit.ProcessModel.MULTIPLE_SECONDARY_PROCESSES
            );
            WebKit.WebContext.get_default().set_favicon_database_directory("/tmp/alaia_favicons");
            WebKit.WebContext.get_default().set_web_extensions_directory(get_lib_directory());
            WebKit.CookieManager cm = WebKit.WebContext.get_default().get_cookie_manager();
            string cachepath = Environment.get_user_cache_dir() + Config.C + "cookies.txt";
            cm.set_persistent_storage(cachepath, WebKit.CookiePersistentStorage.TEXT);

            this.add_window(this.win);
        }

        /**
         * Handles commandline args
         * Strips the first element of the arguments array which is
         * the filename and then causes the main program instance
         * to load the supplied urls as tracks.
         * If there is no ui initialized yet, it will cause it to initialize
         */
        protected override int command_line(ApplicationCommandLine acl) {
            uint cnt = 0;
            string[] urls = new string[acl.get_arguments().length-1];
            foreach (string s in acl.get_arguments()){
                if (cnt > 0)
                    urls[cnt-1] = s;
                cnt++;
            }

            bool init_needed = this.get_windows().length() == 0;
            if (init_needed)
                initialize();
            foreach (string url in urls) {
                this.tracklist.add_track_with_url(url);
            }
            // Start Gtk main loop
            if (init_needed)
                Gtk.main();
            return 0;
        }

        /**
         * Handles more calls to instances
         */
        protected override void activate() {
        }

        /**
         * Callback that initializes the context menu on a webview
         * TODO: exchange Gtk.Action for GLib.Simpleaction as soon as webkitgtk is ready for it
         */
        public bool do_web_context_menu(WebKit.ContextMenu cm, Gdk.Event e, WebKit.HitTestResult htr){
            var w = this.webviews_container.get_nth_page(this.webviews_container.page) as WebView;
            //GLib.SimpleAction a;
            Gtk.Action a;
            cm.remove_all();
            if (w.can_go_back()) {
                //a = new GLib.SimpleAction("navigate-back",null);
                a = new Gtk.Action("navigate-back", _("Go Back"), null, null);
                a.activate.connect(()=>{
                    this.tracklist.current_track.go_back();
                });
                cm.append(new WebKit.ContextMenuItem(a as Gtk.Action));
            }
            if (w.can_go_forward()) {
                //a = new GLib.SimpleAction("navigate-forward",null);
                a = new Gtk.Action("navigate-forward", _("Go Forward"), null, null);
                a.activate.connect(()=>{
                    this.tracklist.current_track.go_forward();
                });
                cm.append(new WebKit.ContextMenuItem(a as Gtk.Action));
            }
            a = new Gtk.Action("view-refresh", _("Reload"), null, null);
            a.activate.connect(()=>{
                this.tracklist.current_track.reload();
            });
            cm.append(new WebKit.ContextMenuItem(a as Gtk.Action));
            return false;
        }

        /**
         * Obtain The WebView that is associated to the given HistoryTrack
         * If no WebView exists yet, it shall be created and added to the
         * Applications WebView-List
         */
        public TrackWebView get_web_view(HistoryTrack t) {
            if (!this.webviews.has_key(t)) {
                var w = new TrackWebView(this.webact);
                w.track = t;
                w.context_menu.connect(do_web_context_menu);
                w.get_context().download_started.connect(t.log_download);
                w.authenticate.connect((request) => {
                    new AuthenticationDialog(this.win.get_stage(), request);
                    return true;
                });
                w.web_process_crashed.connect(() => {
                    ZMQVent.unregister_site();
                    return false;
                });
                this.webviews.set(t,w);
                this.webviews_container.append_page(w);
            }
            return this.webviews.get(t);
        }

        /**
         * Destroys the WebView associated with the given HistoryTrack
         * does nothing if there is no associated WebView
         */
        public void destroy_web_view(HistoryTrack t) {
            if (this.webviews.has_key(t))
                this.webviews[t].destroy();
        }
    
        /**
         * Puts the WebView that corresponds to the given HistoryTrack
         * into the foreground, thereby moving the currently displayed WebView
         * to the background.
         */
        public void show_web_view(HistoryTrack t) {
            if (this.webviews.has_key(t)){
                var page = this.webviews_container.page_num(this.webviews[t]);
                this.webviews_container.set_current_page(page);
                this.webviews_container.show_all();
            }
        }

        /**
         * Checks whether there lies a sessionfile in the cache which can be used
         * to reconstruct a browsing session. This should happen when you start the
         * program.
         */
        public bool old_session_available() {
            return FileUtils.test(GLib.Environment.get_user_cache_dir()+Config.C+SESSION_FILE,
                                    FileTest.EXISTS);
        }

        /**
         * Restores a session from a JSON-file. Performs basic validity checks on the
         * sessionfile. See Also: The [Class].from_json(JsonNode n)-Constructors
         * of several Classes around the Project
         */
        public void restore_session() {
            this.state = TracklistState.S();
            Json.Parser p = new Json.Parser();
            try {
                p.load_from_file(Application.get_cache_filename(SESSION_FILE));
            } catch (GLib.Error e) {
                stdout.printf(_("Could not parse session json\n"));
            }
            var root = p.get_root();
            if (root.get_node_type() != Json.NodeType.OBJECT){
                stdout.printf(_("Invalid session json\n"));
                return;
            }
            unowned Json.Object rootnode = root.get_object();
            foreach (unowned string name in rootnode.get_members()) {
                unowned Json.Node item = rootnode.get_member(name);
                switch(name){
                    case "tracks":
                        this.tracklist.from_json(item);
                        break;
                    default:
                        stdout.printf(_("Unknown session member %s\n"), name);
                        break;
                }
            }
        }

        /**
         * Serializes the current session and writes it to a text-file in JSON format.
         */
        public void save_session() {
            var b = new Json.Builder();
            var valid = this.tracklist.to_json(b);
            if (!valid)
                return;
            var g = new Json.Generator();
            g.set_root(b.get_root());
            string session = g.to_data(null);
            string filename = Application.get_cache_filename(SESSION_FILE);
            try {
                FileUtils.set_data(filename, session.data);
            } catch (FileError e) {
                stdout.printf(_("Could not save session to %s\n"),filename);
            }
        }
        
        /**
         * Callback to close the application.
         */
        public void do_delete() {
            this.save_session();
            Gtk.main_quit();
        }

        /**
         * First Callback an occurring key-event will pass through
         * This method will determine, wheter it is necessary to obtain any further
         * information from web-extension-procecsses.
         * Further it will determine wheter the occurred event is relevant for the
         * current application state and drop it, if not so.
         *
         * If there is no necessity to obtain further information from the
         * web-extensions, the event will be plainly forwarded to
         * do_key_press_event(Gdk.EventKey e)
         *
         * If it is necessary, it will forward the need for information by calling
         * an appropriate method of TrackWebView and passing do_key_press_event(Gdk.EventKey e)
         * as callback and the incoming Gdk.EventKey e.
         * the method of TrackWebView will call do_key_press_event eventually in an asnychronous
         * manner
         */
        public bool preprocess_key_press_event(Gdk.EventKey e) {
            if (this.state is NormalState) {
                var t = this.tracklist.current_track;
                var twv = this.get_web_view(t) as TrackWebView;
                switch(e.keyval) {
                    case Gdk.Key.F2:
                        this.do_key_press_event(e);
                        break;
                    case Gdk.Key.Tab:
                        if (t != null)
                            twv.needs_direct_input(do_key_press_event,e);
                        else
                            this.do_key_press_event(e);
                        break;
                    default:
                        if (twv.is_search_active()) {
                            return false;
                        }
                        this.do_key_press_event(e);
                        break;
                }
            }
            else if (this.state is TracklistState) {
                if (e.keyval !=    Gdk.Key.Tab
                    && e.keyval != Gdk.Key.F2 )
                    return false;
                this.do_key_press_event(e);
            }
            else if (this.state is SessiondialogState) {
                if (e.keyval !=    Gdk.Key.Left
                    && e.keyval != Gdk.Key.Right
                    && e.keyval != Gdk.Key.Return)
                    return false;
                this.do_key_press_event(e);
            }
            else if (this.state is ConfigState) {
                if (e.keyval !=    Gdk.Key.Escape
                    && e.keyval != Gdk.Key.Tab)
                    return false;
                this.do_key_press_event(e);
            }
            return true;
        }

        /**
         * This method executes actions according to an incoming preprocessed
         * Gdk.EventKey e (See preprocess_key_press_event(Gdk.EventKey e) for furhter info)
         * The action that will be taken is depending on which state the application
         * is currently in.
         */
        public void do_key_press_event(Gdk.EventKey e) {
            if (this.state is NormalState) {
                var t = this.tracklist.current_track;
                switch (e.keyval) {
                    case Gdk.Key.Tab:
                        this.state = TracklistState.S();
                        return;
                    case Gdk.Key.F2:
                        this.state = ConfigState.S();
                        return;
                    case Gdk.Key.r:
                        if ((bool)(e.state & Gdk.ModifierType.CONTROL_MASK) && t != null) {
                            t.reload();
                        } else {
                            var wv = this.get_web_view(t);
                            if (wv != null)
                                wv.key_press_event(e);
                        }
                        break;
                    case Gdk.Key.f:
                        if ((bool)(e.state & Gdk.ModifierType.CONTROL_MASK) && t != null) {
                            t.search();
                        } else {
                            var wv = this.get_web_view(t);
                            if (wv != null)
                                wv.key_press_event(e);
                        }
                        break;
                    case Gdk.Key.y:
                        if ((bool)(e.state & Gdk.ModifierType.CONTROL_MASK) && t != null) {
                            var wv = this.get_web_view(t);
                            var c = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
                            c.set_text(wv.get_uri(),-1);
                        } else {
                            var wv = this.get_web_view(t);
                            if (wv != null)
                                wv.key_press_event(e);
                        }
                        break;
                    default:
                        var wv = this.get_web_view(t);
                        if (wv != null)
                            wv.key_press_event(e);
                        break;
                }
            }
            else if (this.state is TracklistState) {
                switch (e.keyval) {
                    case Gdk.Key.Tab:
                        this.state = NormalState.S();
                        return;
                    case Gdk.Key.F2:
                        this.state = ConfigState.S();
                        return;
                }
            }
            else if (this.state is SessiondialogState) {
                switch (e.keyval) {
                    case Gdk.Key.Left:
                        this.sessiondialog.select_restore();
                        return;
                    case Gdk.Key.Right:
                        this.sessiondialog.select_newsession();
                        return;
                    case Gdk.Key.Return:
                        this.sessiondialog.execute_selected();
                        return;
                }
            }
            else if (this.state is ConfigState) {
                switch (e.keyval) {
                    case Gdk.Key.Escape:
                        this.state = NormalState.S();
                        break;
                    case Gdk.Key.Tab:
                        this.state = TracklistState.S();
                        break;
                        
                }
            }
        }

        /**
         * Obtains the singleton instance of Application
         */
        public static Application S() {
            return Application.app;
        }
        
        /**
         * The main method. Initializes GtkClutter and WebKit
         * Then launches the Gtk-Mainloop.
         */
        public static int main(string[] args) {
            if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS){
                stdout.printf(_("Could not initialize GtkClutter"));
            }
            Application.app = new Application();
            return Application.app.run(args);
        }

        /**
         * Returns the location in which the webextensions are most likely stored
         */
        public static string get_lib_directory() {
            File f = File.new_for_path("/usr/lib"+Config.C);
            if (f.query_exists())
                return f.get_path();
            f = File.new_for_path("/usr/local/lib"+Config.C);
            if (f.query_exists())
                return f.get_path();
            else
                return ".";
        }

        /**
         * Returns the full path to name of the given datafile.
         * On *nix-systems it uses the XDG-specifications
         */
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
            return "data/"+Config.C+name;
#else
            return "";
#endif
        }

        /**
         * Returns the full path to name of the given cachefile.
         * On *nix-systems it uses the XDG-specifications
         */
        public static string get_cache_filename(string name) {
            File f = File.new_for_path(GLib.Environment.get_user_cache_dir()+Config.C+name);
            return f.get_path();
#if DEBUG
#else
            return "";
#endif
        }
    }
}
