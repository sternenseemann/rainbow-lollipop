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
     * Errors for the class SiteNode
     */
    public errordomain SiteNodeError {
        NODE_JSON_INVALID // Thrown if a JSON is no proper SiteNode representation
    }

    /**
     * Draws a bright Halo-like gradient which is used to express that
     * A Node currently has the focus.
     */
    public class NodeHighlight  : Clutter.Actor {
        private Clutter.Canvas c;
        private Node parent;

        /**
         * Create a new Node Highlight
         */
        public NodeHighlight(Node parent) {
            this.parent = parent;
            this.c = new Clutter.Canvas();
            this.content = this.c;
            this.opacity = 0x33;
            this.set_size(rnd(parent.width)+20, rnd(parent.height)+20);
            this.c.set_size(rnd(parent.width)+20, rnd(parent.height)+20);
            this.c.draw.connect(do_draw);
            this.x = 0;
            this.y = 0;
            this.c.invalidate();
        }

        /**
         * Draw the node highlight
         */
        public bool do_draw(Cairo.Context cr, int w, int h) {
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_operator(Cairo.Operator.OVER);
            var glow = new Cairo.Pattern.radial(Config.c.node_height/2,Config.c.node_height/2,2,
                                                Config.c.node_height/2,Config.c.node_height/4,100);
            glow.add_color_stop_rgba(0.0,
                                     col_h2f(this.parent.color.red)*2,
                                     col_h2f(this.parent.color.green)*2,
                                     col_h2f(this.parent.color.blue)*2,
                                     1.0);
            glow.add_color_stop_rgba(1.0,
                                     col_h2f(this.parent.color.red),
                                     col_h2f(this.parent.color.green),
                                     col_h2f(this.parent.color.blue),
                                     0.0);
            cr.arc(Config.c.node_height/2,Config.c.node_height/2,Config.c.node_height/2,0,2*Math.PI);
            cr.set_source(glow);
            cr.fill();
            return true;
        }
    }

    /**
     * An animated Actor that is used to indicate that a node is currently loading
     */
    public class NodeSpinner : Clutter.Actor {
        private Clutter.Canvas c;
        private Node parent;
        private bool running = false;

        /**
         * Creates a new NodeSpinner
         */
        public NodeSpinner(Node parent){
            this.parent = parent;
            this.c = new Clutter.Canvas();
            this.x = 0;
            this.y = 0;
            this.content = c;
            this.opacity = 0x00;
            this.set_size(rnd(parent.width), rnd(parent.height));
            this.c.set_size(rnd(parent.width), rnd(parent.height));
            this.c.draw.connect(do_draw);
            this.c.invalidate();
            this.transitions_completed.connect(do_transitions_completed);
            this.set_pivot_point(0.5f, 0.5f);
            this.set_pivot_point_z(0.5f);//Config.c.node_height/2;
            this.start();
        }

        private void do_transitions_completed(){
            if (!this.running) {
                return;
            }
            this.set_easing_mode(Clutter.AnimationMode.EASE_IN_OUT_BOUNCE);
            this.save_easing_state();
            this.rotation_angle_z += 60;
            this.restore_easing_state();
        }

        /**
         * Stop the spinning and make the Node spinner invisible
         */
        public void stop(){
            this.running = false;
            this.save_easing_state();
            this.opacity = 0x00;
            this.restore_easing_state();
        }

        /**
         * Make the spinner visible and start spinning
         */
        public void start(){
            this.running = true;
            this.set_easing_mode(Clutter.AnimationMode.EASE_IN_OUT_BOUNCE);
            this.set_easing_duration(10);
            this.save_easing_state();
            this.rotation_angle_z += 45;
            this.opacity = 0xFF;
            this.restore_easing_state();
        }

        /**
         * Draw the NodeSpinner
         */
        public bool do_draw(Cairo.Context cr, int w, int h) {
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_source_rgba(
                                     col_h2f(this.parent.color.red)/2,
                                     col_h2f(this.parent.color.green)/2,
                                     col_h2f(this.parent.color.blue)/2,
                              1);
            cr.set_operator(Cairo.Operator.OVER);
            cr.set_line_width(2);
            cr.arc(Config.c.node_height/2,Config.c.node_height/2,Config.c.node_height/2-(int)Config.c.bullet_stroke,Math.PI,1.5*Math.PI);
            cr.stroke();
            cr.arc(Config.c.node_height/2,Config.c.node_height/2,Config.c.node_height/2-(int)Config.c.bullet_stroke,0,0.5*Math.PI);
            cr.stroke();
            return true;
        }

    }

    /**
     * An Actor that represents the physical body of a Node
     */
    public class NodeBullet : Clutter.Actor {
        private Clutter.Canvas c;
        private Node parent;

        /**
         * Create a new NodeBullet
         */
        public NodeBullet(Node parent) {
            this.parent = parent;
            this.c = new Clutter.Canvas();
            this.x = 0;
            this.y = 0;
            this.content = c;
            this.set_size(rnd(parent.width), rnd(parent.height));
            this.c.set_size(rnd(parent.width), rnd(parent.height));
            this.c.draw.connect(do_draw);
            this.c.invalidate();
        }

        /**
         * Draw the NodeBullet
         */
        public bool do_draw(Cairo.Context cr, int w, int h) {
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_source_rgba(col_h2f(this.parent.color.red)*2,
                              col_h2f(this.parent.color.green)*2,
                              col_h2f(this.parent.color.blue)*2,
                              1);
            cr.set_operator(Cairo.Operator.OVER);
            cr.set_line_width(Config.c.bullet_stroke);
            cr.arc(Config.c.node_height/2,Config.c.node_height/2,Config.c.node_height/2-(int)Config.c.bullet_stroke,0,2*Math.PI);
            cr.stroke();
            cr.set_source_rgba(col_h2f(this.parent.color.red),
                              col_h2f(this.parent.color.green),
                              col_h2f(this.parent.color.blue),
                              0.5);
            cr.arc(Config.c.node_height/2,Config.c.node_height/2,Config.c.node_height/2,0,2*Math.PI);
            cr.fill();
            return true;
        }
    }

    /**
     * A tooltip that can be attached to an actor
     * TODO: Maybe could be made cooler by attaching to
     *       The Actor's mouse-over events instead of manually coding it there
     */
    public class Tooltip : Clutter.Actor {
        private const uint8 OPACITY = 0xAF;
        private const string COLOR = "#121212";
        protected Clutter.Text textactor;
        private Clutter.Actor par;
        public Tooltip(Clutter.Actor par, string text) {
            this.par = par;
            this.background_color = Clutter.Color.from_string(Tooltip.COLOR);
            this.textactor = new Clutter.Text.with_text("Monospace Bold 9", text);
            this.width = this.textactor.width+2;
            this.height = this.textactor.height+2;
            this.opacity = Tooltip.OPACITY;
            this.visible = false;
            this.textactor.x = 1;
            this.textactor.y = 1;
            this.transitions_completed.connect(do_transitions_completed); 
            this.add_child(this.textactor);
        }

        /**
         * Fade in
         */
        public void emerge() {
            this.scale_x = 1/this.get_parent().scale_x;
            this.visible = true;
            this.textactor.visible = true;
            this.save_easing_state();
            this.textactor.save_easing_state();
            this.opacity = Tooltip.OPACITY;
            this.textactor.opacity = 0xFF;
            this.restore_easing_state();
            this.textactor.restore_easing_state();
        }

        private void do_transitions_completed() {
            if (this.opacity == 0x00) {
                this.visible = false;
                this.textactor.visible = false;
            }
        }

        /**
         * Fade out
         */
        public void disappear() {
            this.save_easing_state();
            this.textactor.save_easing_state();
            this.opacity = 0x00;
            this.textactor.opacity = 0x00;
            this.restore_easing_state();
            this.textactor.restore_easing_state();
        }
    }

    /**
     * A tooltip which attaches to a node and inherits its color for
     * text display
     */
    public class NodeTooltip : Tooltip {
        /**
         * Create a new NodeTooltip
         */
        public NodeTooltip (Node node, string text) {
            base(node, text);
            var c = node.track.get_background_color().lighten();
            c.red = (8+c.red)*10 > 0xFF ? 0xFF : (8+c.red)*10;
            c.green = (8+c.green)*10 > 0xFF ? 0xFF : (8+c.green)*10;
            c.blue = (8+c.blue)*10 > 0xFF ? 0xFF : (8+c.blue)*10;
            this.textactor.color = c;
        }
    }

    /**
     * Represents a call to a Website and its response in a History Track
     * A SiteNode is normally generated when a Site yields neither a Download
     * nor an HTTP-Errorcode
     */
    public class SiteNode : Node {
        private Cairo.Surface favicon;
        private Clutter.Actor favactor;
        private Clutter.Canvas favactor_canvas;
        private NodeBullet bullet;
        private NodeSpinner spinner;
        private NodeHighlight highlight;
        private NodeTooltip url_tooltip;
        
        private string _url;

        /**
         * Holds the URL of the website that has been called to create this node
         */
        [Description(nick="url of this node", blurb="The url that this node represents")]
        public string url {
            get {
                return this._url;
            }
        }

        /**
         * Create a new SiteNode
         */
        public SiteNode(HistoryTrack track, string url, Node? par) {
            base(track, par);
            this._url = url;

            var default_fav_path = Application.get_data_filename("nofav.png");
            this.favicon = new Cairo.ImageSurface.from_png(default_fav_path);
            this.favactor = new Clutter.Actor();
            this.favactor.height=this.favactor.width=Config.c.favicon_size;
            this.favactor.x = this.width/2-this.favactor.width/2;
            this.favactor.y = this.height/2-this.favactor.height/2;
            this.favactor_canvas = new Clutter.Canvas();
            this.favactor_canvas.set_size(Config.c.favicon_size,Config.c.favicon_size);
            this.favactor_canvas.draw.connect(do_draw_favactor);
            this.favactor.content = this.favactor_canvas;
            this.url_tooltip = new NodeTooltip(this, this._url);
            this.add_child(this.url_tooltip);
            this.url_tooltip.x = -this.url_tooltip.width/2+Config.c.node_height/2;
            this.url_tooltip.y = Config.c.node_height;
            this.bullet = new NodeBullet(this);
            this.spinner = new NodeSpinner(this);
            this.highlight = new NodeHighlight(this);

            this.enter_event.connect(do_enter_event);
            this.leave_event.connect(do_leave_event);
            this.transitions_completed.connect(do_transitions_completed);

            this.add_child(this.highlight);
            this.add_child(this.bullet);
            this.add_child(this.favactor);
            this.add_child(this.spinner);
            (this.track.get_parent().get_last_child() as Track).recalculate_y();
            this.clickaction.clicked.connect(do_clicked);
            this.favactor.content.invalidate();
        }

        /**
         * Create a SiteNode from JSON. Usually used to restore a SiteNode
         * from a serialized Session
         * Will recursively Restore all this SiteNode's childnodes
         */
        public SiteNode.from_json(HistoryTrack track, Json.Node n, Node? par) throws SiteNodeError {
            if (n.get_node_type() != Json.NodeType.OBJECT)
                throw new SiteNodeError.NODE_JSON_INVALID("sitenode must be object");
            string url = "";
            bool current = false;
            Json.Array arr_childnodes = null;
            var obj = n.get_object();
            foreach (unowned string name in obj.get_members()) {
                Json.Node item = obj.get_member(name);
                switch(name) {
                    case "current":
                        if (item.get_node_type() != Json.NodeType.VALUE)
                            throw new SiteNodeError.NODE_JSON_INVALID("%s must be value",name);
                        current = item.get_boolean();
                        break;
                    case "url":
                        if (item.get_node_type() != Json.NodeType.VALUE)
                            throw new SiteNodeError.NODE_JSON_INVALID("%s must be value",name);
                        url = item.get_string();
                        break;
                    case "nodes":
                        if (item.get_node_type() != Json.NodeType.ARRAY)
                            throw new SiteNodeError.NODE_JSON_INVALID("%s must be array",name);
                        arr_childnodes = item.get_array();
                        break;
                    default:
                        stdout.printf("invalid field in node onject: %s\n",name);
                        break;
                }
            }
            this(track, url, par);
            if (arr_childnodes != null) {
                foreach (unowned Json.Node item in arr_childnodes.get_elements()) {
                    SiteNode cn;
                    try {
                        cn = new SiteNode.from_json(track, item, this);
                    } catch (SiteNodeError e) {
                        stdout.printf("node creation failed\n");
                    }
                }
            }

            this.stop_spinner();

            if (current)
                this.track.current_node = this;


            //Restore Favicon from cache
            var favdb = WebKit.WebContext.get_default().get_favicon_database();
            string favurl = url;
            if (count_char(favurl,'/') == 2 && !favurl.has_suffix("/"))
                favurl+="/";
            favdb.get_favicon.begin(favurl,null, (obj, res) => {
                Cairo.Surface fav;
                try {
                    fav = favdb.get_favicon.end(res);
                } catch (Error e) { return; }
                this.set_favicon(fav);
            });
        }

        private bool is_current_node = false;

        /**
         * Whatever. Empty method...
         * TODO: Check if really necessary
         */
        public void finish_loading() {

        }

        /**
         * Adapts this nodes appearance to the HistoryTrack that it currently resides
         * in. All subcomponents of this Node then have a color that matches the Track
         * This is for example needed when a Branch of nodes is moved to a new Track
         * By the create-new-track-from-branch-feature.
         */
        public new void adapt_to_track() {
            base.adapt_to_track();
            this.color = this.track.get_background_color().lighten();
            this.color = this.color.lighten();
            this.bullet.content.invalidate();
            this.highlight.content.invalidate();
            this.url_tooltip.content.invalidate();
        }

        /**
         * Toggle this Node's NodeHighlight's visibility
         */
        public void toggle_highlight() {
            this.is_current_node = !this.is_current_node;
            if (this.is_current_node) {
                this.highlight_on();
            } else {
                this.highlight_off();
            }
        }

        /**
         * Sets the NodeHighlight of this Node visible
         */
        public void highlight_on(bool recursive=false) {
            this.is_current_node = true;
            this.highlight.save_easing_state();
            this.highlight.opacity = 0xFF;
            this.highlight.restore_easing_state();
            if (recursive) {
                foreach(Node n in this.childnodes){
                    if (n is SiteNode)
                        (n as SiteNode).highlight_on(recursive);
                }
            }
        }

        /**
         * Sets the NodeHighlight of this Node invisible
         */
        public void highlight_off(bool recursive=false) {
            this.is_current_node=false;
            this.highlight.save_easing_state();
            this.highlight.opacity = 0x00;
            this.highlight.restore_easing_state();
            if (recursive) {
                foreach(Node n in this.childnodes){
                    if (n is SiteNode)
                        (n as SiteNode).highlight_off(recursive);
                }
            }
        }

        /**
         * Activates the Highlight when the mouse enters this SiteNode
         * and the SiteNode is not the current_node of its HistoryTrack
         */
        private bool do_enter_event(Clutter.CrossingEvent e) {
            if (!this.is_current_node) {
                this.highlight.save_easing_state();
                this.highlight.opacity = 0xFF;
                this.highlight.restore_easing_state();
            }
            this.url_tooltip.emerge();
            return true;
        }

        /**
         * Deactivates the Highlight when the mouse leaves this SiteNode
         * except when this SiteNode is its HistoryTrack's current_node
         */
        private bool do_leave_event(Clutter.CrossingEvent e) {
            if (!this.is_current_node) {
                this.highlight.save_easing_state();
                this.highlight.opacity = 0x00;
                this.highlight.restore_easing_state();
            }
            this.url_tooltip.disappear();
            return true;
        }

        private void do_transitions_completed() {
            if (this.opacity == 0x00) {
            }
        }

        /**
         * Stop this SiteNode's NodeSpinner. Thereby stop indicating
         * That this Node is currently loading.
         */
        public void stop_spinner() {
            this.spinner.stop();
        }

        /**
         * Scale and Draw the favicon of this SiteNode
         */
        public bool do_draw_favactor(Cairo.Context cr, int w, int h) {
            var fvcx = new Cairo.Context(this.favicon);
            double x1,x2,y1,y2;
            fvcx.clip_extents(out x1,out y1,out x2,out y2);
            double width = x2-x1;
            double height = y2-y1; 
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.save();
            cr.scale(w/width,h/height);
            cr.set_source_surface(this.favicon,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.restore();
            return true;
        }

        /**
         * Set the favicon of this SiteNode
         */
        public void set_favicon(Cairo.Surface px) {
            this.favicon=px;
            this.favactor_canvas.invalidate();
        }

        /**
         * Enable left mouse button clicks on this SiteNode
         * A Click will cause the WebView of this SiteNode's associated
         * Track to load the url that is stored within this SiteNode
         */
        private new void do_clicked(Clutter.Actor a) {
            base.do_clicked();
            switch (this.clickaction.get_button()) {
                case 1: //Left mousebutton
                    this.track.current_node = this;
                    Application.S().hide_tracklist();
                    break;
            }
        }

        /**
         * Serializes this SiteNode into JSON
         */
        public new void to_json(Json.Builder b) {
            b.begin_object();
            base.to_json(b);
            b.set_member_name("url");
            b.add_string_value(this.url);
            b.set_member_name("current");
            b.add_boolean_value(this.is_current_node);
            b.end_object();
        }
    }
}
