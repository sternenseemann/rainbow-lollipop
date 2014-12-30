using Gee;
using Math;

namespace alaia {
    private float col_h2f(int col) {
        return (float)col/255;
    }

    private int rnd(float f) {
        int i = (int)f;
        float d = f - (float)i;
        if (d > 0.5f) 
            i++;
        return i;
    }

    class ConnectorConstraint : Clutter.Constraint {
        private Clutter.Actor source;
        private Clutter.Actor target;
        
        public ConnectorConstraint(Clutter.Actor source, Clutter.Actor target) {
            this.source=source;
            this.target=target;
        }
        
        public override void update_allocation(Clutter.Actor a, Clutter.ActorBox alloc) {
            var sourcebox = this.source.get_allocation_box();
            var targetbox = this.target.get_allocation_box();
            alloc.x1 = sourcebox.x2;
            alloc.y1 = sourcebox.y1+Config.c.node_height/2;
            alloc.x2 = targetbox.x1;
            alloc.y2 = targetbox.y1+Config.c.node_height/2+3;
            if (alloc.y2-alloc.y1 < (float)Config.c.connector_stroke) {
                alloc.y2 = alloc.y1+(float)Config.c.connector_stroke;
            }
            alloc.clamp_to_pixel();
            (a.content as Clutter.Canvas).set_size(rnd(alloc.x2-alloc.x1), rnd(alloc.y2-alloc.y1));
        }
    }
    
    class Connector : Clutter.Actor {
        private Clutter.Canvas c;
        private Node previous;
        private Node next;

        public Connector(Node previous, Node next) {
            this.previous = previous;
            this.next = next;
            this.c = new Clutter.Canvas();
            this.content = c;
            this.set_size(10,10);
            this.c.set_size(10,10);
            this.x = Config.c.node_height/2+Config.c.track_spacing;
            this.y = 0;
            this.c.draw.connect(do_draw);
            this.add_constraint(
                new ConnectorConstraint(previous, next)
            );
            this.c.invalidate();
            previous.track.add_nodeconnector(this);
            
        }
        public bool do_draw(Cairo.Context cr, int w, int h) {
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_source_rgba(col_h2f(this.previous.color.red)*2,
                              col_h2f(this.previous.color.green)*2,
                              col_h2f(this.previous.color.blue)*2,
                              1);
            cr.set_line_width(Config.c.connector_stroke);
            cr.move_to(0,1);
            if (h < Config.c.node_height) {
                cr.rel_line_to(w,0);
            } else {
                cr.rel_curve_to(w,0,0,h-Config.c.connector_stroke,w,h-Config.c.connector_stroke);
            }
            cr.stroke();
            return true;
        }

        public void emerge() {
            this.visible = true;
            this.save_easing_state();
            this.opacity = 0xFF;
            this.restore_easing_state();
        }
        public void disappear() {
            this.save_easing_state();
            this.opacity = 0x00;
            this.restore_easing_state();
        } 
    }

    class NodeHighlight  : Clutter.Actor {
        private Clutter.Canvas c;
        private Node parent;

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

    class NodeSpinner : Clutter.Actor {
        private Clutter.Canvas c;
        private Node parent;
        private bool running = false;

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

        public void stop(){
            this.running = false;
            this.save_easing_state();
            this.opacity = 0x00;
            this.restore_easing_state();
        }

        public void start(){
            this.running = true;
            this.set_easing_mode(Clutter.AnimationMode.EASE_IN_OUT_BOUNCE);
            this.set_easing_duration(10);
            this.save_easing_state();
            this.rotation_angle_z += 45;
            this.opacity = 0xFF;
            this.restore_easing_state();
        }

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

    class NodeBullet : Clutter.Actor {
        private Clutter.Canvas c;
        private Node parent;

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

    class Tooltip : Clutter.Actor {
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

        public void disappear() {
            this.save_easing_state();
            this.textactor.save_easing_state();
            this.opacity = 0x00;
            this.textactor.opacity = 0x00;
            this.restore_easing_state();
            this.textactor.restore_easing_state();
        }
    }

    class NodeTooltip : Tooltip {
        public NodeTooltip (Node node, string text) {
            base(node, text);
            var c = node.track.get_background_color().lighten();
            c.red = (8+c.red)*10 > 0xFF ? 0xFF : (8+c.red)*10;
            c.green = (8+c.green)*10 > 0xFF ? 0xFF : (8+c.green)*10;
            c.blue = (8+c.blue)*10 > 0xFF ? 0xFF : (8+c.blue)*10;
            this.textactor.color = c;
        }
    }
    
    class Node : Clutter.Actor {
        private Node? previous;
        private Gee.ArrayList<Node> _childnodes; //special list only for nodes
        public Gee.ArrayList<Node> childnodes {get {return this._childnodes;}}
        public HistoryTrack track {get; set;}
        private Cairo.Surface favicon;
        //private Gdk.Pixbuf snapshot;
        private Clutter.Actor favactor;
        private Clutter.Canvas favactor_canvas;
        private NodeBullet bullet;
        private NodeSpinner spinner;
        private NodeHighlight highlight;
        private Connector? connector;
        private NodeTooltip url_tooltip;
        private Clutter.ClickAction clickaction;
        
        public Clutter.Color color {
            get;set;
        }

        private string _url;

        [Description(nick="url of this node", blurb="The url that this node represents")]
        public string url {
            get {
                return this._url;
            }
        }

        public Node(HistoryTrack track, string url, Node? par) {
            this._url = url;
            if (par != null) {
                par.childnodes.add(this);
                this.previous = par;
                if (this.previous.childnodes.size-1 > this.previous.index_of_child(this)) {
                    this.previous.recalculate_nodes();
                }
            }
            track.add_node(this);
            this._childnodes = new Gee.ArrayList<Node>();
            this._track = track;
            this.x = par != null ? par.x : 0;
            this.y = Config.c.track_spacing;
            this.save_easing_state();
            this.x = par.x+par.width+(float)Config.c.node_spacing;
            this.y = Config.c.track_spacing; 
            this.restore_easing_state();
            if (par != null){
                this.connector = new Connector(par,this);
            }
            this.height = Config.c.node_height;
            this.width = Config.c.node_height;
            this.color = track.get_background_color().lighten();
            this.color = this.color.lighten();
            this.reactive = true;

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
            this.url_tooltip.y = -this.url_tooltip.height;
            this.bullet = new NodeBullet(this);
            this.spinner = new NodeSpinner(this);
            this.highlight = new NodeHighlight(this);

            this.clickaction = new Clutter.ClickAction();
            this.add_action(this.clickaction);
            this.clickaction.clicked.connect(do_clicked);
            this.enter_event.connect(do_enter_event);
            this.leave_event.connect(do_leave_event);
            this.transitions_completed.connect(do_transitions_completed);

            this.add_child(this.highlight);
            this.add_child(this.bullet);
            this.add_child(this.favactor);
            this.add_child(this.spinner);
            this.previous.recalculate_y(null);
            (this.track.get_parent().get_last_child() as Track).recalculate_y();
            this.favactor.content.invalidate();
        }

        private bool is_current_node = false;

        public void recalculate_nodes() {
            foreach (Node n in this.childnodes) {
                n.recalculate_y(this);
            }
        }

        public void recalculate_y(Node? call_origin) {
            if (this.previous != null && call_origin != this.previous) {
                this.previous.recalculate_y(this);
                return;
            } else {
                int node_index = this.previous.index_of_child((Node) this);
                int splits_until = this.previous.get_splits_until(node_index);
                var prvy = this.previous.y != 0 ? this.previous.y : Config.c.track_spacing;
                this.y =  prvy + (splits_until+node_index)*(Config.c.node_height+Config.c.track_spacing);
                foreach (Node n in this.childnodes) {
                    n.recalculate_y(this);
                }
            }
        }

        public void finish_loading() {

        }

        public void delete_node(bool rec_initial=true) {
            var prv = this.previous;
            Gee.ArrayList<Node> nodes = new Gee.ArrayList<Node>();
            foreach (Node n in this.childnodes) {
                nodes.add(n);
            }
            foreach (Node n in nodes) {
                n.delete_node(false);
            }
            prv.childnodes.remove(this);
            this.connector.destroy();
            this.destroy();
            prv.recalculate_y(null);
            if (rec_initial){
                (prv.track.get_parent().get_last_child() as Track).recalculate_y(true);
            }
        }

        public Node? get_previous() {
            return this.previous;
        }

        private void detach_childnodes() {
            foreach (Node n in this.childnodes) {
                n.detach_childnodes();
            }
            this.get_parent().remove_child(this);
            this.connector.destroy();
        }

        public void adapt_to_track() {
            this.color = this.track.get_background_color().lighten();
            this.color = this.color.lighten();
            this.bullet.content.invalidate();
            this.highlight.content.invalidate();
            this.url_tooltip.content.invalidate();
            if (this.previous != null) {
                this.connector = new Connector(this.previous, this);
            }
        }
        public void make_root_node() {
            this.previous = null; 
        }

        public void move_to_new_track() {
            this.previous.childnodes.remove(this);
            this.get_parent().remove_child(this);
            this.connector.destroy();
            this.detach_childnodes();
            this.track.tracklist.add_track_with_node(this);
        }

        public int index_of_child(Node n) {
            return this.childnodes.index_of(n);
        }

        public int get_splits() {
            int r = 0;
            foreach (Node n in this.childnodes) {
                r += n.get_splits();
            }
            if (this.childnodes.size > 1) {
                r += this.childnodes.size-1;
            }
            return r;
        }

        public int get_splits_until(int index) {
            int r = 0;
            for (int i = 0; i < index; ++i) {
                r += (this.childnodes.get(i) as Node).get_splits();
            }
            return r;
        }

        public void toggle_highlight() {
            this.is_current_node = !this.is_current_node;
            if (this.is_current_node) {
                this.highlight.save_easing_state();
                this.highlight.opacity = 0xFF;
                this.highlight.restore_easing_state();
            } else {
                this.highlight.save_easing_state();
                this.highlight.opacity = 0x00;
                this.highlight.restore_easing_state();
            }
        }

        private bool do_enter_event(Clutter.CrossingEvent e) {
            if (!this.is_current_node) {
                this.highlight.save_easing_state();
                this.highlight.opacity = 0xFF;
                this.highlight.restore_easing_state();
            }
            this.url_tooltip.emerge();
            return true;
        }

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

        public void stop_spinner() {
            this.spinner.stop();
        }

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

        public void set_favicon(Cairo.Surface px) {
            this.favicon=px;
            this.favactor_canvas.invalidate();
        }

        private void do_clicked(Clutter.Actor a) {
            switch (this.clickaction.get_button()) {
                case 1: //Left mousebutton
                    this.track.current_node = this;
                    break;
                case 3: //Right mousebutton
                    Application.S().context.set_context(this.track,this);
                    Application.S().context.popup(null,null,null,3,0);
                    break;
            }
            this.track.clickaction.release(); //TODO: ugly fix.. there has to be a better way
                                              // Prevents nodes from hanging in a pressed
                                              // state after they have been clicked.
        }

        public void emerge() {
            foreach (Clutter.Actor n in this.get_children()) {
                (n as Node).emerge();
            }
            this.bullet.save_easing_state();
            this.bullet.opacity = 0xE0;
            this.bullet.restore_easing_state();
            this.favactor.save_easing_state();
            this.favactor.opacity = 0xE0;
            this.favactor.restore_easing_state();
            this.connector.emerge();
            if (this.is_current_node) {
                this.highlight.save_easing_state();
                this.highlight.opacity = 0xFF;
                this.highlight.restore_easing_state();
            }
        }

        public void disappear() {
            this.url_tooltip.disappear();
            foreach (Clutter.Actor n in this.get_children()) {
                (n as Node).disappear();
            }
            this.bullet.save_easing_state();
            this.bullet.opacity = 0x00;
            this.bullet.restore_easing_state();
            this.favactor.save_easing_state();
            this.favactor.opacity = 0x00;
            this.favactor.restore_easing_state();
            this.connector.disappear();
            this.highlight.save_easing_state();
            this.highlight.opacity = 0x000;
            this.highlight.restore_easing_state();
        }
    }
}
