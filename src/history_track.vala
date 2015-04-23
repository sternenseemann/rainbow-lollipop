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

namespace RainbowLollipop {
    /**
     * Errors for HistoryTrack
     */
    public errordomain HistoryTrackError {
        TRACK_JSON_INVALID // Thrown if a json does not properly represent a HistoryTrack
    }

    /**
     * The History Track is the core element of this browsers system.
     * A track represents both a space, that a website can be loaded in a parallel fashion
     * to other tracks (what tabs in regular browsers essentially do) and a local browsing
     * history of this space.
     * The history is represented by a tree of nodes that in turn represent single calls
     * to websites.
     */
    public class HistoryTrack : Track {
        public TrackWebView web {get;set;}
        private string url;
        private Clutter.Actor separator;
        private Clutter.Actor nodecontainer;
        private Clutter.Text _title;
        /**
         * reference to the tracklist that this track belongs to.
         */
        public TrackList tracklist {get {return this._tracklist;}}
        private TrackList _tracklist;
        private GtkClutter.Actor close_button;
        public Clutter.ClickAction clickaction;
        private Clutter.Color color;
        private Clutter.Canvas c;

        /**
         * The node that represents the website which is currently being displayed
         * in this HistoryTrack's WebView.
         * If this property is set, it automatically causes the webview to load
         * the site of the new node.
         */
        public Node? current_node {
            get {
                return this._current_node;
            }
            set {
                if (!this.contains(value as Clutter.Actor)){
                    warning ("Cannot assign a Node to a track when it is not a descendant.");
                    return;
                }
                this.tracklist.current_track = this;
                if (this._current_node is SiteNode)
                    (this._current_node as SiteNode).toggle_highlight();
                this.reload_needed = this._current_node != value;
                this._current_node = value;
                if (this._current_node is SiteNode)
                    (this._current_node as SiteNode).toggle_highlight();
            }
        }
        private Node? _current_node;

        /**
         * reference to the root node of this HistoryTrack's node tree
         */
        private Node first_node;
        private bool reload_needed = true;

        /**
         * Add a node to this HistoryTrack
         */
        public void add_node(Node n, bool recursive=false) {
            this.nodecontainer.add_child(n);
            if (recursive) {
                foreach (Node cn in n.childnodes) {
                    this.add_node(cn, recursive);
                }
            }
        }

        /**
         * Add a Nodeconnector to this HistoryTrack
         */
        public void add_nodeconnector(Connector n) {
            this.nodecontainer.add_child(n);
        }

        /**
         * Create a HistoryTrack from an appropriate JSON-node
         * Used to restore sessions.
         */
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
                        SiteNode node;
                        try {
                            node = new SiteNode.from_json(this, item, null);
                        } catch (SiteNodeError e) {
                            stdout.printf("Could not restore rootnode\n");
                            break;
                        }
                        this.first_node = node;
                        this.calculate_height();
                        break;
                    default:
                        stdout.printf("Invalid field in track %s\n",name);
                        break;
                }
            }
        }

        /**
         * Create a HistoryTrack from an existing nodes.
         * This will incorporate all children of the given note into the track
         * Used in the "create track from branch" feature
         */
        public HistoryTrack.with_node(TrackList tl, SiteNode n, SiteNode? cn, string search) {
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
            this.calculate_height();
            
            this.add_childnodes(n);
            if (search != "")
                this.web.start_search(search);
        }

        /**
         * Recursively add all childnodes of a Node n to this track
         */
        private void add_childnodes(Node n) {
            foreach (Node m in n.childnodes) {
                m.track = this;
                if (m is SiteNode)
                    (m as SiteNode).adapt_to_track();
                this.add_child(m);
                this.add_childnodes(m);
            }
        }

        /**
         * Default constructor for HistoryTrack
         * Creates and initializes track UI
         */
        public HistoryTrack(TrackList tl, string url) {
            base(tl);
            this.web = Application.S().get_web_view(this);
            WebKit.BackForwardList bfl = this.web.get_back_forward_list();
            bfl.changed.connect((newnode,_) => {
                if (newnode != null)
                    this.log_call(newnode.get_uri());
            });
            this.web.resource_load_started.connect ((resource, request) => {
                if (this.web.uri == resource.uri)
                    resource.finished.connect(this.do_finished);
            });
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
            Application.S().load_indicator.start();
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

            Config.c.notify.connect(config_update);

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

        /**
         * Draws this HistoryTrack's background
         */
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

        /**
         * The title displayed on top of this Track
         */
        public string title {
            get {
                return this._title.text;
            }
            set {
                this._title.text = value;
            }
        }

        /**
         * Callback that is called when there is a favicon available for the current node
         * TODO: check if it is possible to bind this directly to the concerned node.
         *       relaying it here may cause the false node to be assigned a wrong icon
         */
        public void do_favicon_loaded() {
            this.finish_call(this.web.get_favicon());
        }

        /**
         * Callback to observe if the current node has changed:
         * TODO: there seems to be some redundancy with the code of the current_node
         *       property. check if it is really necessary to do it like that
         */
        private void do_node_changed(GLib.Object self, GLib.ParamSpec p) {
            Application.S().show_web_view(this);
            if (this.reload_needed && this._current_node is SiteNode)
                this.web.load_uri((this._current_node as SiteNode).url);
        }

        /**
         * Callback to a mouseclick on the track.
         * Fires up context menu if clicked
         */
        private void do_clicked(Clutter.Actor a) {
            switch(this.clickaction.get_button()) {
                case 3:
                    Application.S().context.set_context(this,null);
                    Application.S().context.popup(null,null,null,3,0);
                    break;
            }
        }

        /**
         * Causes this HistoryTrack's webview to reload
         */
        public void reload() {
            Application.S().get_web_view(this).reload();
        }

        /**
         * Causes HistoryTrack and Browser to go to the previous node and load
         * its associated website.
         */
        public void go_back() {
            Node? prv = this.current_node.get_previous();
            if (prv != null) {
                this.current_node = prv;
            }
        }

        /**
         * Go to one of the following nodes
         * TODO: implement
         */
        public void go_forward() {
        }

        /**
         * Handles changes in config
         */
        private void config_update() {
            this.calculate_height();
        }

        /**
         * Calculates how many pixels this HistoryTrack needs in vertical space
         */
        public override int calculate_height(bool animated=true) {
            if (animated)
                this.save_easing_state();
            int h = Config.c.track_spacing+((Config.c.node_height+Config.c.track_spacing)*(this.first_node.get_splits()+1));
            this.height = h;
            if (animated)
                this.restore_easing_state();
            return h;
        }

        /**
         * Log a call to a website by creating a new SiteNode and making it the
         * current_node of this HistoryTrack
         */
        public void log_call(string uri) {
            if (this._current_node is SiteNode &&
                uri != (this._current_node as SiteNode).url) {
                History.S().log_call(uri);
                var nn = new SiteNode(this, uri, this._current_node);
                Application.S().load_indicator.start();
                (this._current_node as SiteNode).toggle_highlight();
                (this._current_node as SiteNode).recalculate_y(null);
                this._current_node = nn;
                (this._current_node as SiteNode).toggle_highlight();
            }
        }

        /**
         * Log a download by creating a DownloadNode.
         * TODO: currently we can only place downloadnodes correctly
         *       after a sitenode has already been created.
         *       maybe we can somehow determine if there should be a download
         *       node instead of a site node in the phase of the WebKit loading state
         *       WebKit.LoadEvent.STARTED
         *       Same problem exists in log_error()
         */
        public void log_download(WebKit.Download d) {
            var fsn = this._current_node;
            if (Application.S().tracklist.current_track == this){
                this._current_node = fsn.get_previous();
                fsn.delete_node();
                new DownloadNode(this, d, this._current_node);
            }
        }

        /**
         * This method gets called when the current website finishes loading
         * a resource.
         * If an error occurs, it  will remove the node that represents the
         * website and replace it with an errornode.
         * TODO: Same as in log_download()
         */
        public void do_finished() {
            var resource = this.web.get_main_resource();
            var fsn = this._current_node;
            uint status = resource.get_response().status_code;
            if (status == 0 )
                return;
            if (status ==  200) {
                this.finish_call(this.web.get_favicon());
                this.title = this.web.title;
            } else {
                if (Application.S().tracklist.current_track == this){
                    this._current_node = fsn.get_previous();
                    fsn.delete_node();
                    new ErrorNode(this, status, this._current_node);
                }
            }
        }

        /**
         * Stops the current node indicating that it is loading and sets
         * its favicon, if there is any.
         */
        public void finish_call(Cairo.Surface? favicon) {
            if(this._current_node is SiteNode) {
                if (favicon != null){
                    (this._current_node as SiteNode).set_favicon(favicon);
                }
                (this._current_node as SiteNode).stop_spinner();
                Application.S().load_indicator.stop();
            }
        }

        /**
         * Causes this tracks webview to show up the fulltext search overlay
         */
        public void search() {
            var webview = Application.S().get_web_view(this) as TrackWebView;
            if (webview != null) {
                webview.start_search();
            }
        }

        /**
         * This method shall be called every time this track
         * is selected as the current track.
         */
        public new void prepare() {
            base.prepare();
            var wv = Application.S().get_web_view(this) as TrackWebView;
            wv.restore_search();
        }

        /**
         * This method shall be called every time this track
         * ceases to be the current_track of the Tracklist
         * and performs cleanup operations.
         */
        public new void cleanup() {
            base.cleanup();
            var wv = Application.S().get_web_view(this) as TrackWebView;
            wv.hide_search();
        }
        
        public override void emerge() {
            base.emerge();
            this.close_button.opacity = 0xFF;
        }

        public override void disappear() {
            base.disappear();
            this.close_button.opacity = 0x00;
        }

        /**
         * Delete this HistoryTrack
         */
        public new void delete_track() {
            this.close_button.destroy();
            Application.S().destroy_web_view(this);
            base.delete_track();
        }

        /**
         * Serialize this HistoryTrack to JSON
         */
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
