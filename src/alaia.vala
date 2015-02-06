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

    class IPCCallbackWrapper {
        private IPCCallback cb;
        private Gdk.EventKey e;
        private TrackWebView w;

        public IPCCallbackWrapper(TrackWebView web, IPCCallback cb, Gdk.EventKey e) {
            this.cb = cb;
            this.e = e;
            this.w = web;
        }

        public IPCCallback get_callback() {
            return this.cb;
        }
        public Gdk.EventKey get_event() {
            return this.e;
        }
        public TrackWebView get_webview() {
            return this.w;
        }
    }

    public delegate void IPCCallback(Gdk.EventKey e);

    class ZMQVent {
        private static const string VENT = "tcp://127.0.0.1:26010";

        private static uint32 callcounter = 0;
        private static ZMQ.Context ctx;
        private static ZMQ.Socket sender;

        private static uint32 _current_sites = 0;
        public static uint32 current_sites {get{return ZMQVent._current_sites;}}

        public static void init() {
            ZMQVent.ctx = new ZMQ.Context(1);
            ZMQVent.sender = ZMQ.Socket.create(ctx, ZMQ.SocketType.PUSH);
            ZMQVent.sender.bind(ZMQVent.VENT);
        }

        public static async void needs_direct_input(TrackWebView w,IPCCallback cb, Gdk.EventKey e) {
            uint64 page_id = w.get_page_id();
            stdout.printf("ohai\n");
            //Create Callback
            uint32 callid = callcounter++;
            var cbw = new IPCCallbackWrapper(w, cb, e);
            ZMQSink.register_callback(callid, cbw);
            string msgstring = IPCProtocol.NEEDS_DIRECT_INPUT+
                               IPCProtocol.SEPARATOR+
                               "%lld".printf(page_id)+
                               IPCProtocol.SEPARATOR+
                               "%ld".printf(callid);
            for (int i = 0; i < ZMQVent.current_sites; i++) {
                var msg = ZMQ.Msg.with_data(msgstring.data);
                sender.send(ref msg);
                stdout.printf("sending stuff %s\n",msgstring);
            }
        }

        public static void register_site() {
            ZMQVent._current_sites++;
        }

        public static void unregister_site() {
            if (ZMQVent._current_sites > 0)
                ZMQVent._current_sites--;
        }
    }

    class ZMQSink {
        private static const string SINK = "tcp://127.0.0.1:26011";

        private static Gee.HashMap<uint32, IPCCallbackWrapper> callbacks;
        private static ZMQ.Context ctx;
        private static ZMQ.Socket receiver;

        public static void register_callback(uint32 callid, IPCCallbackWrapper cbw) {
            ZMQSink.callbacks.set(callid, cbw);
        }

        public static void init() {
            stdout.printf("initializing sink\n");
            ZMQSink.callbacks = new Gee.HashMap<uint32, IPCCallbackWrapper>();
            ZMQSink.ctx = new ZMQ.Context(1);
            ZMQSink.receiver = ZMQ.Socket.create(ctx, ZMQ.SocketType.PULL);
            ZMQSink.receiver.bind(ZMQSink.SINK);
            try {
                stdout.printf("creating thread\n");
                unowned Thread<void*> worker_thread = Thread.create<void*>(ZMQSink.run, true);
                stdout.printf("created thread\n");
            } catch (ThreadError e) {
                stdout.printf("Sink broke down\n");
            }
        }

        public static void* run() {
            stdout.printf("ohai thread\n");
            while (true) {
                var input = ZMQ.Msg(); 
                stdout.printf("core - receiving shit\n");
                receiver.recv(ref input);
                stdout.printf((string)input.data+"\n");
                ZMQSink.handle_response((string)input.data);
            }
        }

        private static void handle_response(string input) {
            if (input.has_prefix(IPCProtocol.REGISTER)) {
                string[] splitted = input.split(IPCProtocol.SEPARATOR);
                ZMQVent.register_site();
            }
            if (input.has_prefix(IPCProtocol.NEEDS_DIRECT_INPUT_RET)) {
                stdout.printf("in here\n");
                string[] splitted = input.split(IPCProtocol.SEPARATOR);
                uint64 page_id = uint64.parse(splitted[1]);
                int result = int.parse(splitted[2]);
                uint32 call_id = int.parse(splitted[3]);
                IPCCallbackWrapper? cbw = ZMQSink.callbacks.get(call_id);
                stdout.printf("result : %d\n",result);
                if (result == 1) {
                    stdout.printf("here too\n2");
                    GLib.Idle.add(() => {
                        cbw.get_webview().key_press_event(cbw.get_event());
                        return false;
                    });
                } else {
                    stdout.printf("here\n");
                    GLib.Idle.add(() => {
                        cbw.get_callback()(cbw.get_event());
                        return false;
                    });
                }
                ZMQSink.callbacks.unset(call_id);
            }
            return;
        }

    }

    public class IPCProtocol : Object {
        public static const string NEEDS_DIRECT_INPUT = "ndi";
        public static const string NEEDS_DIRECT_INPUT_RET = "r_ndi";
        public static const string ERROR = "error";
        public static const string REGISTER = "reg";
        public static const string SEPARATOR = "-";
    }

    public class TrackWebView : WebKit.WebView {
        public HistoryTrack track{ get;set; }

        public TrackWebView() {
        }

        public async void needs_direct_input(IPCCallback cb, Gdk.EventKey e) {
            stdout.printf("ohai2\n");
            ZMQVent.needs_direct_input(this, cb, e);
        }
    }

    class ContextMenu : Gtk.Menu {
        private Gtk.ImageMenuItem new_track_from_node;
        private Gtk.ImageMenuItem delete_branch;
        private Gtk.ImageMenuItem copy_url;
        private Gtk.ImageMenuItem delete_track;
        private Gtk.ImageMenuItem open_folder;
        private Gtk.ImageMenuItem open_download;
        private Node? node;
        private Track? track;
        
        public ContextMenu () {
            //Nodes
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

            //Sitenodes
            this.copy_url = new Gtk.ImageMenuItem.with_label("Copy URL");
            this.copy_url.set_image(
                new Gtk.Image.from_icon_name("edit-copy", Gtk.IconSize.MENU)
            );
            this.copy_url.activate.connect(do_copy_url);
            this.add(this.copy_url);


            //DownloadNodes
            this.open_folder = new Gtk.ImageMenuItem.with_label("Open folder");
            this.open_folder.set_image(
                new Gtk.Image.from_icon_name("folder", Gtk.IconSize.MENU)
            );
            this.open_folder.activate.connect(do_open_folder);
            this.add(this.open_folder);
            this.open_download = new Gtk.ImageMenuItem.with_label("Open");
            this.open_download.set_image(
                new Gtk.Image.from_icon_name("document-open", Gtk.IconSize.MENU)
            );
            this.open_download.activate.connect(do_open_download);
            this.add(this.open_download);

            //Track
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
            this.copy_url.visible = this.node != null && this.node is SiteNode;
            this.open_folder.visible = this.node != null && this.node is DownloadNode;
            this.open_download.visible = this.node != null && this.node is DownloadNode &&
                                         (this.node as DownloadNode).is_finished();
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

    class Application : Gtk.Application {
        private static Application app;

        private GtkClutter.Window win;
        private ContextMenu _context;
        public ContextMenu context {get{return _context;}}
        private Gee.HashMap<HistoryTrack,WebKit.WebView> webviews;
        private Gtk.Notebook webviews_container;
        private GtkClutter.Actor webact;

        public TrackList tracklist {get;set;}
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

            ZMQVent.init();
            ZMQSink.init();
            
            this._state = AppState.TRACKLIST;

            this.webviews = new Gee.HashMap<HistoryTrack, TrackWebView>();
            this.webviews_container = new Gtk.Notebook();
            this.webviews_container.show_tabs = false;
            this.webact = new GtkClutter.Actor.with_contents(this.webviews_container);

            this.win = new GtkClutter.Window();
            this.win.set_title("alaia");
            this.win.maximize();
            this.win.icon_name="alaia";
            this.win.key_press_event.connect(preprocess_key_press_event);
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
                var w = new TrackWebView();
                w.track = t;
                w.context_menu.connect(do_web_context_menu);
                w.get_context().download_started.connect(t.log_download);
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

        public void show_tracklist() {
            this.tracklist_background.emerge();
            this._state = AppState.TRACKLIST;
        }
        public void hide_tracklist() {
            this.tracklist_background.disappear();
            this._state = AppState.NORMAL;
        }
        
        public void do_needs_direct_input(bool ndi) {
        }

        public bool preprocess_key_press_event(Gdk.EventKey e) {
            var t = this.tracklist.current_track;
            if (e.keyval != Gdk.Key.Tab) {
                return false;
            }
            if (t != null) {
                //this.do_key_press_event(e);
                //return true;
                (this.get_web_view(t) as TrackWebView).needs_direct_input(do_key_press_event,e);
            } else {
                this.do_key_press_event(e);
            }
            return true;
        }

        public void do_key_press_event(Gdk.EventKey e) {
            switch (this._state) {
                case AppState.NORMAL:
                    switch (e.keyval) {
                        case Gdk.Key.Tab:
                            this.show_tracklist();
                            return;
                        default:
                            return;
                    }
                case AppState.TRACKLIST:
                    switch (e.keyval) {
                        case Gdk.Key.Tab:
                            this.hide_tracklist();
                            return;
                        default:
                            return;
                    }
            }
        }

        public static Application S() {
            return Application.app;
        }
        
        public static int main(string[] args) {
            if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS){
                stdout.printf("Could not initialize GtkClutter");
            }
            Application.app = new Application();
            WebKit.WebContext.get_default().set_process_model(
                WebKit.ProcessModel.MULTIPLE_SECONDARY_PROCESSES
            );
            WebKit.WebContext.get_default().set_favicon_database_directory("/tmp/alaia_favicons");
            stdout.printf(get_data_filename("wpe")+"\n");
            WebKit.WebContext.get_default().set_web_extensions_directory(get_data_filename("alaia/wpe"));
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
