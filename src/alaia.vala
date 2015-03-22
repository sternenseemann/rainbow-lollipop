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
     * A reference to a HistoryTrack along with it and offers methods
     * To communicate with the web-extension-process of this view.
     */
    public class TrackWebView : WebKit.WebView {
        /**
         * Stores a reference to the HistoryTrack that is associated with
         * This WebView
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
         * Asks The web-extension-process wheter this webview currently
         * Needs input from the keyboard e.g. to fill content into a
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
        public void start_search() {
            this.search.visible = this.searchstate = true;
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
     * The ContextMenu of Items displayed in the TrackList.
     * It displays different Actions according to what object has been clicked on:
     *
     * Track:
     *    - Close Track
     * Node:
     *    - Close Branch
     *    - New Track from Branch
     *    + SiteNode:
     *       - Copy URL
     *    + DownloadNode:
     *       - Open the downloaded File
     *       - Open the folder in which the downloaded file resides.
     */
    class ContextMenu : Gtk.Menu {
        private Gtk.ImageMenuItem new_track_from_node;
        private Gtk.ImageMenuItem delete_branch;
        private Gtk.ImageMenuItem copy_url;
        private Gtk.ImageMenuItem delete_track;
        private Gtk.ImageMenuItem open_folder;
        private Gtk.ImageMenuItem open_download;
        private Node? node;
        private Track? track;

        /**
         * Initializes the ContextMenu
         */
        public ContextMenu () {
            //Nodes
            this.new_track_from_node = new Gtk.ImageMenuItem.with_label(_("New Track from Branch"));
            this.new_track_from_node.set_image(
                new Gtk.Image.from_icon_name("go-jump", Gtk.IconSize.MENU)
            );
            this.new_track_from_node.activate.connect(do_new_track_from_node);
            this.add(this.new_track_from_node);
            this.delete_branch = new Gtk.ImageMenuItem.with_label(_("Close Branch"));
            this.delete_branch.set_image(
                new Gtk.Image.from_icon_name("edit-delete", Gtk.IconSize.MENU)
            );
            this.delete_branch.activate.connect(do_delete_branch);
            this.add(this.delete_branch);

            //Sitenodes
            this.copy_url = new Gtk.ImageMenuItem.with_label(_("Copy URL"));
            this.copy_url.set_image(
                new Gtk.Image.from_icon_name("edit-copy", Gtk.IconSize.MENU)
            );
            this.copy_url.activate.connect(do_copy_url);
            this.add(this.copy_url);


            //DownloadNodes
            this.open_folder = new Gtk.ImageMenuItem.with_label(_("Open folder"));
            this.open_folder.set_image(
                new Gtk.Image.from_icon_name("folder", Gtk.IconSize.MENU)
            );
            this.open_folder.activate.connect(do_open_folder);
            this.add(this.open_folder);
            this.open_download = new Gtk.ImageMenuItem.with_label(_("Open"));
            this.open_download.set_image(
                new Gtk.Image.from_icon_name("document-open", Gtk.IconSize.MENU)
            );
            this.open_download.activate.connect(do_open_download);
            this.add(this.open_download);

            //Track
            this.add(new Gtk.SeparatorMenuItem());
            this.delete_track = new Gtk.ImageMenuItem.with_label(_("Close Track"));
            this.delete_track.set_image(
                new Gtk.Image.from_icon_name("window-close", Gtk.IconSize.MENU)
            );
            this.delete_track.activate.connect(do_delete_track);
            this.add(this.delete_track);

            this.show_all();
        }

        /**
         * This method shows/hides actions of the menu according to whether
         * they are needed or not. The context is expressed by the combination
         * of either a track and a node, a track without a node or nothing.
         */
        public void set_context(Track? track, Node? node) {
            this.track = track;
            this.node = node;
            
            this.delete_track.visible = this.track != null;
            this.new_track_from_node.visible = this.node != null;
            this.copy_url.visible = this.node != null && this.node is SiteNode;
            this.open_folder.visible = this.node != null && this.node is DownloadNode;
            this.open_download.visible = this.node != null && this.node is DownloadNode &&
                                         (this.node as DownloadNode).is_finished();
            this.delete_branch.visible = this.node != null;
        }

        /**
         * Callbacks
         */
        public void do_new_track_from_node(Gtk.MenuItem m) {
            if (this.node != null)
                this.node.move_to_new_track();
        }
        public void do_delete_branch(Gtk.MenuItem m) {
            if (this.node  != null)
                this.node.delete_node();
        }
        public void do_copy_url(Gtk.MenuItem m) {
            if (this.node != null && this.node is SiteNode){
                var c = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
                c.set_text((this.node as SiteNode).url,-1);
            }
        }
        public void do_delete_track(Gtk.MenuItem m) {
            if (this.track != null)
                this.track.delete_track();
        }
        public void do_open_folder(Gtk.MenuItem m) {
            if (this.node is DownloadNode)
                (this.node as DownloadNode).open_folder();
        }
        public void do_open_download(Gtk.MenuItem m) {
            if (this.node is DownloadNode)
                (this.node as DownloadNode).open_download();
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
        private Gee.HashMap<HistoryTrack,WebKit.WebView> webviews;
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

            //Internationalization
            init_locale();

            // Load config
            Config.load();

            // Initialize the IPC-Classes
            ZMQVent.init();
            ZMQSink.init();
            
            // Initialize stuff to display WebViews
            this.webviews = new Gee.HashMap<HistoryTrack, TrackWebView>();
            this.webviews_container = new Gtk.Notebook();
            this.webviews_container.show_tabs = false;
            this.webact = new GtkClutter.Actor.with_contents(this.webviews_container);

            NormalState.init(this.webact);

            // Initialize the main window
            this.win = new GtkClutter.Window();
            this.win.set_title("alaia");
            this.win.maximize();
            this.win.icon_name="alaia";
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

            // Initialize Tracklist


            // Show everything that is needed on screen.
            this.win.show_all();
            this.sessiondialog.disappear();
            this.tracklist_background.disappear();

            if (this.old_session_available())
                this.state = SessiondialogState.S();
            else
                this.state = TracklistState.S();

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
         * If no WebView Exists yet, it shall be created and added to the
         * Applications WebView-List
         */
        public WebKit.WebView get_web_view(HistoryTrack t) {
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
         * Does nothing if there is no associated WebView
         */
        public void destroy_web_view(HistoryTrack t) {
            if (this.webviews.has_key(t))
                this.webviews[t].destroy();
        }
    
        /**
         * Puts the WebView that corresponds to the given HistoryTrack
         * Into the foreground, thereby moving the currently displayed WebView
         * To the background.
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
         * To reconstruct a browsing session. This should happen when you start the
         * Program.
         */
        public bool old_session_available() {
            return FileUtils.test(GLib.Environment.get_user_cache_dir()+Config.C+SESSION_FILE,
                                    FileTest.EXISTS);
        }

        /**
         * Restores a session from a JSON-file. Performs basic validity checks on the
         * Sessionfile. See Also: The [Class].from_json(JsonNode n)-Constructors
         * Of several Classes around the Project
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
         * First Callback an occuring key-event will pass through
         * This method will determine, wheter it is necessary to obtain any further
         * Information from web-extension-procecsses.
         * Further it will determine wheter the occured event is relevant for the
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
                if (e.keyval != Gdk.Key.Tab)
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
            return true;
        }

        /**
         * This method executes actions according to an incoming preprocessed
         * Gdk.EventKey e (See preprocess_key_press_event(Gdk.EventKey e) for furhter info)
         * The action that will be taken is depending on which state the application
         * Is currently in.
         */
        public void do_key_press_event(Gdk.EventKey e) {
            if (this.state is NormalState) {
                var t = this.tracklist.current_track;
                switch (e.keyval) {
                    case Gdk.Key.Tab:
                        this.state = TracklistState.S();
                        return;
                    case Gdk.Key.r:
                        if ((bool)(e.state & Gdk.ModifierType.CONTROL_MASK) && t != null) {
                            t.reload();
                        }
                        break;
                    case Gdk.Key.f:
                        if ((bool)(e.state & Gdk.ModifierType.CONTROL_MASK) && t != null) {
                            t.search();
                        }
                        break;
                }
            }
            else if (this.state is TracklistState) {
                switch (e.keyval) {
                    case Gdk.Key.Tab:
                        this.state = NormalState.S();
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
            WebKit.WebContext.get_default().set_process_model(
                WebKit.ProcessModel.MULTIPLE_SECONDARY_PROCESSES
            );
            WebKit.WebContext.get_default().set_favicon_database_directory("/tmp/alaia_favicons");
            WebKit.WebContext.get_default().set_web_extensions_directory(get_lib_directory());
            Gtk.main();
            return 0;
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
