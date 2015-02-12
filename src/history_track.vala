namespace alaia {
    public errordomain HistoryTrackError {
        TRACK_JSON_INVALID
    }

    public class HistoryTrack : Track {
        private WebKit.WebView web;
        private string url;
        private Clutter.Actor separator;
        private Clutter.Actor nodecontainer;
        private Clutter.Text _title;
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
                if (this._current_node is SiteNode)
                    (this._current_node as SiteNode).toggle_highlight();
                this.reload_needed = this._current_node != value;
                this._current_node = value;
                if (this._current_node is SiteNode)
                    (this._current_node as SiteNode).toggle_highlight();
            }
        }
        private Node first_node;
        private bool reload_needed = true;

        public void add_node(Node n, bool recursive=false) {
            this.nodecontainer.add_child(n);
            if (recursive) {
                foreach (Node cn in n.childnodes) {
                    this.add_node(cn, recursive);
                }
            }
        }

        public void add_nodeconnector(Connector n) {
            this.nodecontainer.add_child(n);
        }

        public HistoryTrack.from_json(TrackList tl, Json.Node n) throws HistoryTrackError {
            this(tl, "");
            if (n.get_node_type() != Json.NodeType.OBJECT){
                throw new HistoryTrackError.TRACK_JSON_INVALID("Track json is invalid");
            }
            var obj = n.get_object();
            foreach (unowned string name in obj.get_members()){
                var item = obj.get_member(name);
                switch (name){
                    case "title":
                        if (item.get_node_type() != Json.NodeType.VALUE)
                            throw new HistoryTrackError.TRACK_JSON_INVALID("%s must be value", name);
                        this.title = item.get_string();
                        break;
                    case "current":
                        if (item.get_node_type() != Json.NodeType.VALUE)
                            throw new HistoryTrackError.TRACK_JSON_INVALID("%s must be value", name);
                        if (item.get_boolean())
                            tl.current_track = this;
                        break;
                    case "first_node":
                        var node = new SiteNode.from_json(this, item, null);
                        break;
                    default:
                        stdout.printf("Invalid field in track %s\n",name);
                        break;
                }
            }
        }

        public HistoryTrack.with_node(TrackList tl, SiteNode n) {
            this(tl, n.url);
            this.web.load_uri(n.url);
            this.remove_child(this.first_node);
            this.first_node.destroy();
            this.first_node = n;
            this.add_node(this.first_node,true);
            n.highlight_off(true);
            this.current_node = this.first_node;
            this.url = n.url;

            this.first_node.make_root_node();
            this.first_node.track = this;
            n.adapt_to_track();
            this.first_node.recalculate_y(null);
            
            this.add_childnodes(n);
        }

        private void add_childnodes(Node n) {
            foreach (Node m in n.childnodes) {
                m.track = this;
                if (m is SiteNode)
                    (m as SiteNode).adapt_to_track();
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

            this.first_node = new SiteNode(this, url, null);
            this.notify["current-node"].connect(do_node_changed);
            this.current_node = this.first_node;
            this.url = url;

            this.color = this.background_color;
            this.c = new Clutter.Canvas();
            this.content = this.c;
            this.set_size(40,this.calculate_height());
            this.c.set_size((int)this.width,(int)this.height);
            this.c.draw.connect(this.do_draw);
            this.x = 0;
            this.y = 0;
            this.c.invalidate();

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

            this._title = new Clutter.Text.with_text("Monospace Bold 9", "");
            this._title.color = this.background_color.lighten().lighten();
            this._title.add_constraint(
                new Clutter.AlignConstraint(this, Clutter.AlignAxis.X_AXIS,0.5f)
            );
            this.add_child(this._title);

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

        public string title {
            get {
                return this._title.text;
            }
            set {
                this._title.text = value;
            }
        }

        public void do_load_committed(WebKit.LoadEvent e) {
            switch (e) {
                case WebKit.LoadEvent.STARTED:
                    // Ignore loading the current_node of a saved session
                    if (this.web.get_uri() == null || this.web.get_uri() == "")
                        break;

                    // Ignore if the node has the same URL as the
                    // currently displayed website
                    if (this._current_node != null
                            && this._current_node is SiteNode
                            && this.web.get_uri() == (this._current_node as SiteNode).url+"/") {
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
                    this.title = this.web.title;
                    break;
            }
        }

        public void do_favicon_loaded() {
            this.finish_call(this.web.get_favicon());
        }

        private void do_node_changed(GLib.Object self, GLib.ParamSpec p) {
            Application.S().show_web_view(this);
            if (this.reload_needed && this._current_node is SiteNode)
                this.web.load_uri((this._current_node as SiteNode).url);
        }

        private void do_clicked(Clutter.Actor a) {
            switch(this.clickaction.get_button()) {
                case 3:
                    Application.S().context.set_context(this,null);
                    Application.S().context.popup(null,null,null,3,0);
                    break;
            }
        }

        public void go_back() {
            Node? prv = this.current_node.get_previous();
            if (prv != null) {
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
            if (this._current_node is SiteNode &&
                uri != (this._current_node as SiteNode).url) {
                var nn = new SiteNode(this, uri, this._current_node);
                (this._current_node as SiteNode).toggle_highlight();
                (this._current_node as SiteNode).recalculate_y(null);
                this._current_node = nn;
                (this._current_node as SiteNode).toggle_highlight();
            }
        }

        public void log_download(WebKit.Download d) {
            var fsn = this._current_node;
            if (Application.S().tracklist.current_track == this){
                this._current_node = fsn.get_previous();
                fsn.delete_node();
                new DownloadNode(this, d, this._current_node);
            }
        }

        public void finish_call(Cairo.Surface? favicon) {
            if(this._current_node is SiteNode) {
                if (favicon != null){
                    (this._current_node as SiteNode).set_favicon(favicon);
                }
                (this._current_node as SiteNode).stop_spinner();
            }
        }
        
        public new void emerge() {
            base.emerge();
            this.close_button.opacity = 0xFF;
        }

        public new void disappear() {
            base.disappear();
            this.close_button.opacity = 0x00;
        }

        public new void delete_track() {
            this.close_button.destroy();
            Application.S().destroy_web_view(this);
            base.delete_track();
        }

        public void to_json(Json.Builder b) {
            b.begin_object();
            b.set_member_name("title");
            b.add_string_value(this.title);
            b.set_member_name("current");
            b.add_boolean_value(Application.S().tracklist.current_track == this);
            b.set_member_name("first_node");
            if (this.first_node is SiteNode)
                (this.first_node as SiteNode).to_json(b);
            else
                b.add_null_value();
            b.end_object();
        }
    }
}
