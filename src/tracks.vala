using WebKit;

namespace alaia {
    class TrackColorSource : GLib.Object {
        private static Gee.ArrayList<string> colors;
        private static int state = 0;
        private static bool initialized = false;
        
        public static void init() {
            if (!TrackColorSource.initialized) {
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

    class TrackCloseButton : Clutter.Actor {
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

    abstract class Track : Clutter.Actor {
        private const uint8 OPACITY = 0xE0;
        public const uint8 HEIGHT = 0x80;
        public const uint8 SPACING = 0x10;

        private float ypos;

        public Track(TrackList tl) {
            Track last_track = (tl.get_last_child() as Track);
            if (last_track != null) {
                this.y = last_track.y;
                this.save_easing_state();
                this.y += last_track.height;
                this.restore_easing_state();
            }
            this.add_constraint(
                new Clutter.BindConstraint(tl, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.background_color = TrackColorSource.get_color();
            this.height = this.calculate_height();
            this.opacity = Application.S().state == AppState.TRACKLIST ? Track.OPACITY : 0x00;
            this.visible = Application.S().state == AppState.TRACKLIST;
            this.notify.connect(do_y_offset);
            this.transitions_completed.connect(do_transitions_completed);
            (this.get_parent().get_last_child() as Track).recalculate_y(0);
        }

        ~Track(){
            (this.get_parent().get_last_child() as Track).recalculate_y(0);
        }

        private void do_transitions_completed() {
            if (this.opacity == 0x00) {
                this.visible = false;
            }
        }

        private void do_y_offset(GLib.Object t, ParamSpec p) {
            if (p.name == "y-offset") {
                var last = this.get_parent().get_last_child();
                (last as Track).recalculate_y((t as HistoryTrack).y_offset,false);
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

        public int recalculate_y(float y_offset, bool animated=true){
            var previous = (this.get_previous_sibling() as Track);
            if (animated) 
                this.save_easing_state();
            this.ypos = previous != null ? previous.recalculate_y(y_offset,animated) : 0;
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

        public EmptyTrack(TrackList tl) {
            base(tl);
            this.tracklist = tl;
            this.url_entry = new Gtk.Entry();
            this.enter_button = new Gtk.Button.with_label("Go");
            this.hbox = new Gtk.HBox(false, 5);
            this.background_color = Clutter.Color.from_string("#555");
            this.hbox.pack_start(this.url_entry,true);
            this.hbox.pack_start(this.enter_button,false);
            this.url_entry.activate.connect(do_activate);
            this.actor = new GtkClutter.Actor.with_contents(this.hbox);
            this.actor.height=26;
            this.actor.y = Track.HEIGHT/2-this.actor.height/2;
            this.actor.add_constraint(
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.add_constraint(
                new Clutter.BindConstraint(tl, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.actor.transitions_completed.connect(do_transitions_completed);
            this.actor.show_all();
            this.actor.visible = false;
            this.add_child(this.actor);
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

        public HistoryTrack(TrackList tl, string url, WebView web) {
            base(tl);
            this.web = web;
            this.tracklist = tl;
            this.web.open(url);
            this.first_node = new Node(this, url, null);
            this.current_node = this.first_node;
            this.url = url;

            this.tracking = false;
            this.x_delta = 0;
            this._x_offset = 80;
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
                var nn = new Node(this, wf.get_uri(), this._current_node);
                this._current_node.toggle_highlight();
                this._current_node.recalculate_y();
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

    class TrackList : Clutter.Actor {
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
            this.stage = stage;
            
            this.add_constraint(
                new Clutter.BindConstraint(stage, Clutter.BindCoordinate.SIZE,0)
            );
            this.background_color = Clutter.Color.from_string("#121212");
            this.reactive=true;
            this.opacity = 0x00;
            this.visible = true;
            this.transitions_completed.connect(do_transitions_completed);
            this.add_empty_track();
        }

        public void add_track(string url) {
            this.insert_child_at_index(
                new HistoryTrack(this, url, this.web),
                this.get_n_children()-1
            );
        }

        private void add_empty_track() {
            this.add_child(
                new EmptyTrack(this)
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
            for (int i = 0; i < this.get_n_children(); i++) {
                Track t = (this.get_child_at_index(i) as Track);
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
            for (int i = 0; i < this.get_n_children(); i++) {
                Track t = (this.get_child_at_index(i) as Track);
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
