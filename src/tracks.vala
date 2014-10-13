using WebKit;

namespace alaia {
    class TrackColorSource : GLib.Object {
        private static Gee.ArrayList<string> colors;
        private static int state = 0;
        private static bool initialized = false;
        
        public static void init() {
            if (!TrackColorSource.initialized) {
                stdout.printf("init");
                TrackColorSource.colors = new Gee.ArrayList<string>();
                TrackColorSource.colors.add("#550");
                TrackColorSource.colors.add("#050");
                TrackColorSource.colors.add("#055");
                TrackColorSource.colors.add("#005");
                TrackColorSource.colors.add("#505");
                TrackColorSource.colors.add("#500");
                TrackColorSource.initialized = true;
            }
        }

        public static Clutter.Color get_color() {
            TrackColorSource.init();
            var color = TrackColorSource.colors.get(TrackColorSource.state);
            if (++TrackColorSource.state == TrackColorSource.colors.size) {
                TrackColorSource.state = 0;
            }
            return Clutter.Color.from_string(color);
        }
    }

    class TrackCloseButton : Clutter.Rectangle {
        private Track track;
        private Clutter.Actor stage;

        public TrackCloseButton (Clutter.Actor stage, Track track) {
            this.button_press_event.connect(do_button_press_event);
        }

        private bool do_button_press_event (Clutter.ButtonEvent e) {
            //delete this.track;
            return false;
        }
    }

    abstract class Track : Clutter.Rectangle {
        private const uint8 OPACITY = 0xE0;
        public const uint8 HEIGHT = 0x80;
        public const uint8 SPACING = 0x10;
        protected Clutter.Actor stage;

        private Track? previous;
        private weak Track? next;

        private float ypos;

        public Track(Clutter.Actor tl, Track? prv, Track? nxt) {
            this.previous = prv;
            this.next = nxt;
            if (this.previous != null) {
                this.previous.next = this;
            }
            if (this.next != null) {
                this.next.previous = this;
            }
            this.add_constraint(
                new Clutter.BindConstraint(tl, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.color = TrackColorSource.get_color();
            this.height = this.calculate_height();
            this.opacity = Application.S().state == AppState.TRACKLIST ? Track.OPACITY : 0x00;
            this.visible = Application.S().state == AppState.TRACKLIST;
            this.notify.connect(do_y_offset);
            this.transitions_completed.connect(do_transitions_completed);
            tl.add_child(this);
            this.stage = tl;
            this.get_last_track().recalculate_y(0);
        }

        ~Track(){
            this.next.previous = this.previous;
            this.previous.next = this.next;

            this.get_last_track().recalculate_y(0);
        }

        private void do_transitions_completed() {
            if (this.opacity == 0x00) {
                this.visible = false;
            }
        }

        private void do_y_offset(GLib.Object t, ParamSpec p) {
            if (p.name == "y-offset") {
                this.get_last_track().recalculate_y((t as HistoryTrack).y_offset,false);
            }
        }        

        public void emerge() {
            this.visible = true;
            this.save_easing_state();
            this.opacity = Track.OPACITY;
            this.restore_easing_state();
        }
        public void disappear() {
            this.save_easing_state();
            this.opacity = 0x00;
            this.restore_easing_state();
        }

        protected abstract int calculate_height();

        private Track get_first_track() {
            return this.previous == null ? this : this.previous.get_first_track();
        }

        public Track get_last_track() {
            return this.next == null ? this : this.next.get_last_track();
        }

        public int recalculate_y(float y_offset, bool animated=true){
            if (animated) 
                this.save_easing_state();
            this.ypos = this.previous != null ? this.previous.recalculate_y(y_offset,animated) : 0;
            this.y = this.ypos + y_offset;
            if (this is HistoryTrack) {
                (this as HistoryTrack).set_yoff(y_offset);
            }
            if (animated)
                this.restore_easing_state();
            return this.calculate_height() + (int)this.ypos;
        }
    }

    class EmptyTrack : Track {
        private Gtk.Entry url_entry;
        private Gtk.Button enter_button;
        private Gtk.HBox hbox;
        private GtkClutter.Actor actor; 
        private TrackList tracklist;

        public EmptyTrack(Clutter.Actor stage, Track? prv, Track? nxt, TrackList tl) {
            base(stage, prv, nxt);
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
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.Y, Track.HEIGHT/2-this.actor.height/2)  
            );
            
            this.actor.height=25;
            this.actor.transitions_completed.connect(do_transitions_completed);
            this.actor.show_all();
            this.actor.visible = false;
            this.y = this.get_stage().get_height()/2-Track.HEIGHT;
            stage.add_child(this.actor);
        }

        private void do_activate() {
            var url = this.url_entry.get_text();
            if (!url.has_prefix("http://") && !url.has_prefix("https://")) {
                url = "http://" + url;
            }
            this.tracklist.add_track(url);
        }

        private void do_transitions_completed() {
            if (this.actor.opacity == 0x00) {
                this.actor.visible=false;
            }
        }

        protected override int calculate_height(){
            return Track.HEIGHT;
        }

        public new void emerge() {
            base.emerge();
            this.actor.visible = true;
            this.actor.save_easing_state();
            this.actor.opacity = 0xE0;
            this.actor.restore_easing_state();
            this.url_entry.grab_focus();
        }

        public new void disappear() {
            base.disappear();
            this.actor.save_easing_state();
            this.actor.opacity = 0x00;
            this.actor.restore_easing_state();
        }
        
    }

    class HistoryTrack : Track {
        private WebKit.WebView web;
        private string url;
        private TrackList tracklist;

        private bool tracking;
        private float x_delta;
        private float _x_offset;
        public float x_offset {
            set {
                this._x_offset = value;
            }
            get {
                return this._x_offset;
            }
        }
        private float y_delta;
        private float _y_offset;
        public float y_offset {
            set {
                this._y_offset = value;
            }
            get {
                return this._y_offset;
            }
        }
        public void set_yoff(float yo) {
            this._y_offset = yo;
        }

        private Node? _current_node;
        public Node? current_node {
            get {
                return this._current_node;
            }
            set {
                this.tracklist.current_track = this;
                this._current_node.toggle_highlight();
                this._current_node = value;
                this._current_node.toggle_highlight();
            }
        }
        private Node first_node;

        public HistoryTrack(Clutter.Actor stage, Track? prv, Track? nxt, TrackList tl, string url, WebView web) {
            base(stage,prv,nxt);
            this.web = web;
            this.tracklist = tl;
            this.web.open(url);
            this.first_node = new Node(stage, this, url, null);
            this._current_node = this.first_node;
            this.url = url;

            this.tracking = false;
            this.x_delta = 0;
            this.reactive = true;
            this.leave_event.connect(do_leave_event);
            this.button_press_event.connect(do_button_press_event);
            this.button_release_event.connect(do_button_release_event);
            this.motion_event.connect(do_motion_event);
            this.notify.connect(do_notify);
        }

        private bool do_leave_event(Clutter.CrossingEvent e) {
            this.tracking = false;
            return true;
        }

        private bool do_button_press_event(Clutter.ButtonEvent e){
            if (e.button == Gdk.BUTTON_MIDDLE) {
                this.tracking = true;
                this.x_delta = e.x - this._x_offset;
                this.y_delta = e.y - this._y_offset;
                return true;
            } else {
                return false;
            }
        }

        private bool do_button_release_event(Clutter.ButtonEvent e) {
            if (e.button == Gdk.BUTTON_MIDDLE) {
                this.tracking = false;
                return true;
            } else {
                return false;
            }
        }

        private bool do_motion_event(Clutter.MotionEvent e) {
            if (this.tracking) {
                this.x_offset = e.x-x_delta;
                this.y_offset = e.y-y_delta;
                return true;
            } else {
                return false;
            }
        }

        private void do_notify(GLib.Object self, GLib.ParamSpec p) {
            if (p.name == "current_node") {
                this.web.open(this._current_node.url);
            }
        }

        public void load_page(Node n) {
            this.web.open(n.url);
        }

        protected override int calculate_height() {
            int h = Track.SPACING+((Node.HEIGHT+Track.SPACING)*(this.first_node.get_splits()+1));
            this.height = h;
            return h;
        }

        public void log_call(WebFrame wf) {
            if (wf.get_uri() != this._current_node.url) {
                var nn = new Node(this.stage, this, wf.get_uri(), this._current_node);
                this._current_node.toggle_highlight();
                this._current_node = nn;
                this._current_node.toggle_highlight();
                this.web.icon_loaded.connect(do_icon_loaded);
            }
        }
        private void do_icon_loaded(string b) {
            this._current_node.set_favicon(this.web.get_icon_pixbuf());
            this.web.icon_loaded.disconnect(do_icon_loaded);
        }
        
        public new void emerge() {
            base.emerge();
            if (this.first_node != null) {
                this.first_node.emerge();
            }
        }

        public new void disappear() {
            base.disappear();
            if (this.first_node != null) {
                this.first_node.disappear();
            }
        }
    }

    class TrackList : Clutter.Rectangle {
        private Gee.ArrayList<Track> tracks;
        private Clutter.Actor stage;
        private WebKit.WebView web;
        
        public HistoryTrack? current_track {
            get {
                return this._current_track;
            }
            set {
                this._current_track = value;
            }
            
        }

        private HistoryTrack? _current_track;

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
            Track? next = null;
            Track? previous = null;

            if (this.tracks.size >= 1) {
                next = this.tracks.get(this.tracks.size-1);
            }

            if (this.tracks.size >= 2) {
                previous = this.tracks.get(this.tracks.size-2);
            }

            var nt = new HistoryTrack(this.stage, previous, next, this, url, this.web);
            this.tracks.insert(this.tracks.size-1, nt);
            
            this._current_track = nt;
        }

        private void add_empty_track() {
            this.tracks.insert(this.tracks.size,
                new EmptyTrack(this.stage, null, null,  this)
            );
        }

        public void log_call(WebKit.WebFrame wf) {
            if (this._current_track != null) {
                this._current_track.log_call(wf);
            }
        }

        private void do_transitions_completed() {
            if (this.opacity == 0x00) {
                this.visible = false;
            }
        }
        
        public void emerge() {
            foreach (Track t in this.tracks) {
                if (t is EmptyTrack) {
                    (t as EmptyTrack).emerge();
                } else {
                    (t as HistoryTrack).emerge();
                }
            }
            this.visible = true;
            this.save_easing_state();
            this.opacity = 0xE0;
            this.restore_easing_state();
        }

        public void disappear() {
            foreach (Track t in this.tracks){
                if (t is EmptyTrack) {
                    (t as EmptyTrack).disappear();
                } else {
                    (t as HistoryTrack).disappear();
                }
            }
            this.save_easing_state();
            this.opacity = 0x00;
            this.restore_easing_state();
        }
    }
}
