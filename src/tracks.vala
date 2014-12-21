using WebKit;

namespace alaia {
    class TrackColorSource : GLib.Object {
        private static Gee.ArrayList<string> colors;
        private static int state = 0;
        private static bool initialized = false;
        
        public static void init() {
            if (!TrackColorSource.initialized) {
                TrackColorSource.colors = new Gee.ArrayList<string>();
                foreach (string color in Config.c.colorscheme.tracks) {
                    TrackColorSource.colors.add(color);
                }
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

    abstract class Track : Clutter.Actor {
        public Track(TrackList tl) {
            Track last_track = (tl.get_last_child() as Track);
            if (last_track != null) {
                this.y = last_track.y;
                this.save_easing_state();
                this.restore_easing_state();
            }
            this.add_constraint(
                new Clutter.BindConstraint(tl, Clutter.BindCoordinate.WIDTH, 0)
            );


            this.opacity = Application.S().state == AppState.TRACKLIST ? Config.c.track_opacity : 0x00;
            this.visible = Application.S().state == AppState.TRACKLIST;

            this.transitions_completed.connect(do_transitions_completed);
            this.background_color = TrackColorSource.get_color();
            this.height = this.calculate_height();
            (this.get_parent().get_last_child() as Track).recalculate_y(true);
        }

        ~Track(){
            (this.get_parent().get_last_child() as Track).recalculate_y(true);
        }

        private void do_transitions_completed() {
            if (this.opacity == 0x00) {
                this.visible = false;
            }
        }

        public void emerge() {
            this.visible = true;
            this.save_easing_state();
            this.opacity = Config.c.track_opacity;
            this.restore_easing_state();
        }
        public void disappear() {
            this.save_easing_state();
            this.opacity = 0x00;
            this.restore_easing_state();
        }

        public bool delete_track () {
            Track par = (Track)this.get_parent().get_last_child();
            this.destroy();
            par.recalculate_y();
            return false;
        }

        protected abstract int calculate_height();

        public int recalculate_y(bool animated=true){
            var previous = (this.get_previous_sibling() as Track);

            if (animated) 
                this.save_easing_state();

            var ypos = this.y = previous != null ? previous.recalculate_y(animated) : 0;

            if (animated)
                this.restore_easing_state();

            return this.calculate_height() + (int)ypos;
        }
    }

    class EmptyTrack : Track {
        private Gtk.Entry url_entry;
        private Gtk.Button enter_button;
        private Gtk.Grid hbox;
        private GtkClutter.Actor actor; 
        private TrackList tracklist;

        public EmptyTrack(TrackList tl) {
            base(tl);
            this.tracklist = tl;
            this.url_entry = new Gtk.Entry();
            this.enter_button = new Gtk.Button.with_label("Go");
            this.hbox = new Gtk.Grid();
            this.background_color = Clutter.Color.from_string(Config.c.colorscheme.empty_track);
            this.hbox.add(this.url_entry);
            this.hbox.add(this.enter_button);
            this.url_entry.expand=true;
            this.url_entry.activate.connect(do_activate);
            this.actor = new GtkClutter.Actor.with_contents(this.hbox);
            this.actor.height=26;
            this.actor.y = Config.c.track_height/2-this.actor.height/2;
            this.actor.add_constraint(
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.add_constraint(
                new Clutter.BindConstraint(tl, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.actor.transitions_completed.connect(do_transitions_completed);
            this.hbox.show_all();
            this.actor.visible = false;
            this.add_child(this.actor);
        }

        private void do_activate() {
            var url = this.url_entry.get_text();
            if (!url.has_prefix("http://") && !url.has_prefix("https://")) {
                url = "http://" + url;
            }
            this.tracklist.add_track_with_url(url);
        }

        private void do_transitions_completed() {
            if (this.actor.opacity == 0x00) {
                this.actor.visible=false;
            }
        }

        protected override int calculate_height(){
            return Config.c.track_height;
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
        private Clutter.Actor separator;
        private Clutter.Actor nodecontainer;
        private Clutter.Text title;
        private TrackList _tracklist;
        public TrackList tracklist {get {return this._tracklist;}}
        private GtkClutter.Actor close_button;
        public Clutter.ClickAction clickaction;
        private Clutter.Color color;
        private Clutter.Canvas c;

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

        public void add_node(Node n) {
            this.nodecontainer.add_child(n);
        }

        public void add_nodeconnector(Connector n) {
            this.nodecontainer.add_child(n);
        }

        public HistoryTrack.with_node(TrackList tl, Node n) {
            this(tl, n.url);
            this.web.load_uri(n.url);
            this.remove_child(this.first_node);
            this.first_node.destroy();
            this.first_node = n;
            this.add_child(this.first_node);
            this.current_node = this.first_node;
            this.url = n.url;

            this.first_node.make_root_node();
            this.first_node.track = this;
            this.first_node.adapt_to_track();
            this.first_node.recalculate_y(null);
            
            this.clickaction = new Clutter.ClickAction();
            this.add_action(this.clickaction);
            this.clickaction.clicked.connect(do_clicked);

            this.add_childnodes(n);
        }

        private void add_childnodes(Node n) {
            foreach (Node m in n.childnodes) {
                m.track = this;
                m.adapt_to_track();
                this.add_child(m);
                this.add_childnodes(m);
            }
        }

        public HistoryTrack(TrackList tl, string url) {
            base(tl);
            this.web = Application.S().get_web_view(this);
            this.web.load_changed.connect(do_load_committed);
            this.web.notify["favicon"].connect((e,p) => {this.do_favicon_loaded();});
            this._tracklist = tl;
            this.web.load_uri(url);
 
            this.nodecontainer = new Clutter.Actor();
            this.nodecontainer.add_constraint(
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.SIZE,0)
            );
            this.nodecontainer.y = 0;
            this.nodecontainer.x = 0x20;
            this.nodecontainer.reactive = true;
            this.add_child(nodecontainer);

            this.first_node = new Node(this, url, null);
            this.notify["current-node"].connect(do_node_changed);
            this.current_node = this.first_node;
            this.url = url;

            this.color = this.background_color;
            this.c = new Clutter.Canvas();
            this.content = this.c;
            this.set_size(40,this.calculate_height());
            this.c.set_size((int)this.width,(int)this.height);
            this.c.draw.connect(this.do_draw);
            stdout.printf("invalidate\n");
            this.x = 0;
            this.y = 0;
            this.c.invalidate();
            stdout.printf("invalidated\n");

            var close_img = new Gtk.Image.from_icon_name("window-close", Gtk.IconSize.SMALL_TOOLBAR);
            var button = new Gtk.Button();
            button.margin=0;
            button.set_image(close_img);
            this.close_button = new GtkClutter.Actor.with_contents(button);
            button.clicked.connect(()=>{this.delete_track();});
            this.close_button.visible = true;
            this.close_button.height = this.close_button.width = 32;
            this.add_child(this.close_button);

            this.separator = new Clutter.Actor();
            this.separator.background_color = this.background_color.lighten();
            this.separator.height = 1;
            this.separator.y = 0;
            this.separator.x = 0;
            this.separator.visible = true;
            this.separator.add_constraint(
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.WIDTH,0)
            );
            this.add_child(separator);

            this.title = new Clutter.Text.with_text("Monospace Bold 9", "");
            this.title.color = this.background_color.lighten().lighten();
            this.title.add_constraint(
                new Clutter.AlignConstraint(this, Clutter.AlignAxis.X_AXIS,0.5f)
            );
            this.add_child(this.title);

            this.clickaction = new Clutter.ClickAction();
            this.add_action(this.clickaction);
            this.clickaction.clicked.connect(do_clicked);

            this.reactive = true;
            var action = new Clutter.PanAction();
            action.pan_axis = Clutter.PanAxis.X_AXIS;
            action.interpolate = true;
            action.deceleration = 0.75;
            this.nodecontainer.add_action(action);
        }

        private bool do_draw(Cairo.Context cr, int w, int h) {
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            var grad = new Cairo.Pattern.linear(0,0,0,h);
            grad.add_color_stop_rgba(0.0,
                                     col_h2f(this.color.red),
                                     col_h2f(this.color.green),
                                     col_h2f(this.color.blue),
                                     1.0);
            grad.add_color_stop_rgba(1.0,
                                     col_h2f(this.color.red)-0.3f,
                                     col_h2f(this.color.green)-0.3f,
                                     col_h2f(this.color.blue)-0.3f,
                                     1.0);
            cr.rectangle(0,0,w,h);
            cr.set_source(grad);
            cr.fill();
            return true;
        }

        public void set_title(string t) {
            this.title.text = t;
        }

        public void do_load_committed(WebKit.LoadEvent e) {
            switch (e) {
                case WebKit.LoadEvent.STARTED:
                    if (this._current_node != null
                            && this.web.get_uri() == this._current_node.url+"/") {
                        break;
                    }
                    this.log_call(this.web.get_uri());
                    break;
                case WebKit.LoadEvent.REDIRECTED:
                    break;
                case WebKit.LoadEvent.COMMITTED:
                    break;
                case WebKit.LoadEvent.FINISHED:
                    this.finish_call(this.web.get_favicon());
                    this.set_title(this.web.title);
                    break;
            }
        }

        public void do_favicon_loaded() {
            this.finish_call(this.web.get_favicon());
        }

        private void do_node_changed(GLib.Object self, GLib.ParamSpec p) {
            Application.S().show_web_view(this);
            this.web.load_uri(this._current_node.url);
        }

        private void do_clicked(Clutter.Actor a) {
            switch(this.clickaction.get_button()) {
                case 3:
                    Application.S().context.set_context(this,null);
                    Application.S().context.popup(null,null,null,3,0);
                    break;
            }
        }

        public void load_page(Node n) {
            this.web.load_uri(n.url);
        }

        public void go_back() {
            Node? prv = this.current_node.get_previous();
            if (prv != null) {
                load_page(prv);
                this.current_node = prv;
            }
        }

        //TODO: implement
        public void go_forward() {
        }

        protected override int calculate_height() {
            int h = Config.c.track_spacing+((Config.c.node_height+Config.c.track_spacing)*(this.first_node.get_splits()+1));
            this.height = h;
            return h;
        }

        public void log_call(string uri) {
            if (uri != this._current_node.url) {
                var nn = new Node(this, uri, this._current_node);
                this._current_node.toggle_highlight();
                this._current_node.recalculate_y(null);
                this._current_node = nn;
                this._current_node.toggle_highlight();
            }
        }

        public void finish_call(Cairo.Surface? favicon) {
            if (favicon != null){
                this._current_node.set_favicon(favicon);
            }
            this._current_node.stop_spinner();
        }
        
        public new void emerge() {
            base.emerge();
            this.close_button.opacity = 0xFF;
            if (this.first_node != null) {
                this.first_node.emerge();
            }
        }

        public new void disappear() {
            base.disappear();
            this.close_button.opacity = 0x00;
            if (this.first_node != null) {
                this.first_node.disappear();
            }
        }

        public new void delete_track() {
            this.close_button.destroy();
            base.delete_track();
        }
    }

    class TrackListBackground : Clutter.Actor {
        public TrackListBackground(Clutter.Actor stage) {
            var tl = new TrackList(this);
            this.visible = true;
            this.add_constraint(
                new Clutter.BindConstraint(stage, Clutter.BindCoordinate.SIZE,0)
            );
            this.background_color = Clutter.Color.from_string(Config.c.colorscheme.tracklist);
            this.transitions_completed.connect(do_transitions_completed);
            var action = new Clutter.PanAction();
            action.pan_axis = Clutter.PanAxis.Y_AXIS;
            action.interpolate = true;
            action.deceleration = 0.75;
            this.add_action(action);
            this.reactive = true;
            this.add_child(tl);
        }

        public void emerge() {
            var tl = (TrackList)this.get_first_child();
            if (tl != null)
                tl.emerge();
            this.visible = true;
            this.save_easing_state();
            this.opacity = 0xE0;
            this.restore_easing_state();
        }

        public void disappear() {
            var tl = (TrackList)this.get_first_child();
            if (tl != null)
                tl.disappear();
            this.save_easing_state();
            this.opacity = 0x00;
            this.restore_easing_state();
        }

        private void do_transitions_completed() {
            if (this.opacity == 0x00) {
                this.visible = false;
            }
        }

    }

    class TrackList : Clutter.Actor {
        public HistoryTrack? current_track {
            get {
                return this._current_track;
            }
            set {
                this._current_track = value;
            }
            
        }

        private HistoryTrack? _current_track;

        public TrackList(TrackListBackground tbl) {
            this.add_constraint(
                new Clutter.BindConstraint(tbl, Clutter.BindCoordinate.WIDTH,0)
            );
            this.add_constraint(
                new Clutter.AlignConstraint(tbl, Clutter.AlignAxis.Y_AXIS, 0.5f)
            );
            this.reactive=true;
            this.opacity = 0x00;
            this.visible = true;
            this.transitions_completed.connect(do_transitions_completed);
            this.notify["current-track"].connect((d,e)=>{
                        Application.S().show_web_view(this.current_track);
                    });
            this.add_empty_track();
        }

        public void add_track_with_url(string url) {
            var t = new HistoryTrack(this, url);
            this.insert_child_at_index(
                t,
                this.get_n_children()-1
            );
            (this.get_last_child() as Track).recalculate_y(true);
        }

        public void add_track_with_node(Node n) {
            var t = new HistoryTrack.with_node(this, n);
            this.insert_child_at_index(
                t,
                this.get_n_children()-1
            );
            (this.get_last_child() as Track).recalculate_y(true);
        }

        public Track? get_track_of_node(Node n){
            foreach (Clutter.Actor t in this.get_children()) {
                if (t is HistoryTrack && (t as HistoryTrack).contains(n)) {
                    return (t as HistoryTrack);
                }
            }
            return null;
        }

        private void add_empty_track() {
            this.add_child(
                new EmptyTrack(this)
            );
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
