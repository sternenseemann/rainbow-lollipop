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
            alloc.y1 = sourcebox.y1 + this.source.height/2;
            alloc.x2 = targetbox.x1;
            alloc.y2 = (targetbox.y1 + this.target.height/2) + 3 ;
            if (alloc.y2-alloc.y1 < (float)Connector.STROKE_WIDTH) {
                alloc.y2 = alloc.y1+(float)Connector.STROKE_WIDTH;
            }
            alloc.clamp_to_pixel();
            (a.content as Clutter.Canvas).set_size(rnd(alloc.x2-alloc.x1), rnd(alloc.y2-alloc.y1));
        }
    }
    
    class Connector : Clutter.Actor {
        private Clutter.Canvas c;
        private Node previous;
        private Node next;
        public const double STROKE_WIDTH = 2.0;

        public Connector(Node previous, Node next) {
            this.previous = previous;
            this.next = next;
            this.c = new Clutter.Canvas();
            this.content = c;
            this.set_size(10,10);
            this.c.set_size(10,10);
            this.x = previous.x+previous.width;
            this.y = previous.y+previous.height;
            this.c.draw.connect(do_draw);
            this.add_constraint(
                new ConnectorConstraint(previous, next)
            );
            this.c.invalidate();
            this.previous.get_stage().add_child(this);
            
        }
        public bool do_draw(Cairo.Context cr, int w, int h) {
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_source_rgba(col_h2f(this.previous.color.red)*2,
                              col_h2f(this.previous.color.green)*2,
                              col_h2f(this.previous.color.blue)*2,
                              1);
            cr.set_line_width(STROKE_WIDTH);
            cr.move_to(0,1);
            if (h < Node.HEIGHT) {
                cr.rel_line_to(w,0);
            } else {
                cr.rel_curve_to(w,0,0,h-STROKE_WIDTH,w,h-STROKE_WIDTH);
            }
            cr.stroke();
            return true;
        } 
    }

    class NodeHighlight  : Clutter.Actor {
        private Clutter.Canvas c;
        private Node parent;

        public NodeHighlight(Node parent) {
            this.parent = parent;
            this.c = new Clutter.Canvas();
            this.content = this.c;
            this.reactive = true;
            this.opacity = 0x33;
            this.set_size(rnd(parent.width)+20, rnd(parent.height)+20);
            this.c.set_size(rnd(parent.width)+20, rnd(parent.height)+20);
            this.c.draw.connect(do_draw);
            this.add_constraint(
                new Clutter.BindConstraint(parent, Clutter.BindCoordinate.POSITION,0)
            );
            this.c.invalidate();
        }

        public bool do_draw(Cairo.Context cr, int w, int h) {
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_operator(Cairo.Operator.OVER);
            var glow = new Cairo.Pattern.radial(Node.HEIGHT/2,Node.HEIGHT/2,2,
                                                Node.HEIGHT/2,Node.HEIGHT/4,100);
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
            cr.arc(Node.HEIGHT/2,Node.HEIGHT/2,Node.HEIGHT/2,0,2*Math.PI);
            cr.set_source(glow);
            cr.fill();
            return true;
        }
    }

    class NodeBullet : Clutter.Actor {
        private const double STROKE_WIDTH = 5.0;
        private Clutter.Canvas c;
        private Node parent;

        public NodeBullet(Node parent) {
            this.parent = parent;
            this.c = new Clutter.Canvas();
            this.content = c;
            this.reactive=true;
            this.set_size(rnd(parent.width), rnd(parent.height));
            this.c.set_size(rnd(parent.width), rnd(parent.height));
            this.c.draw.connect(do_draw);
            this.add_constraint(
                new Clutter.BindConstraint(parent, Clutter.BindCoordinate.ALL,0)
            );
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
            cr.set_line_width(STROKE_WIDTH);
            cr.arc(Node.HEIGHT/2,Node.HEIGHT/2,Node.HEIGHT/2-(int)STROKE_WIDTH,0,2*Math.PI);
            cr.stroke();
            cr.set_source_rgba(col_h2f(this.parent.color.red),
                              col_h2f(this.parent.color.green),
                              col_h2f(this.parent.color.blue),
                              0.5);
            cr.arc(Node.HEIGHT/2,Node.HEIGHT/2,Node.HEIGHT/2,0,2*Math.PI);
            cr.fill();
            return true;
        }
    }
    
    class NodeConstraint : Clutter.Constraint {
        private Node previous;

        public NodeConstraint(Node previous) {
            this.previous = previous;
        }

        public override void update_allocation(Clutter.Actor a, Clutter.ActorBox alloc){
            stdout.printf("lel %d\n",this.previous.index_nextnode((Node)a));
            alloc.x1 = this.previous.x+Node.HEIGHT+Track.SPACING;
            alloc.x2 = this.previous.x+Track.SPACING+2*Node.HEIGHT;
            stdout.printf("y1 %f\n",this.previous.y+this.previous.index_nextnode((Node)a)*(Node.HEIGHT+Track.SPACING));
            alloc.y1 = this.previous.y+this.previous.index_nextnode((Node)a)*(Node.HEIGHT+Track.SPACING);
            alloc.y2 = alloc.y1+Node.HEIGHT;
            alloc.clamp_to_pixel();
        }
    }

    class Node : Clutter.Actor {
        public static const uint8 COL_MULTIPLIER = 15;
        public static const uint8 HEIGHT = 0x40;
        public static const uint8 FAVICON_SIZE = 32;
        private Gee.ArrayList<Node> next;
        private Node? previous;
        private HistoryTrack track;
        private Clutter.Actor stage;
        private float xpos;
        private Gdk.Pixbuf favicon;
        private Gdk.Pixbuf snapshot;
        private Clutter.Actor favactor;
        private NodeBullet bullet;
        private NodeHighlight highlight;
        
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

        public Node(Clutter.Actor stage, HistoryTrack track, string url, Node? prv) {
            this._url = url;
            this.previous = prv;
            this.next = new Gee.ArrayList<Node>();
            this.track = track;
            this.track.notify.connect(do_x_offset);
            this.stage = stage;
            this.xpos = 100;
            this.x = this.xpos;
            if (prv != null){
                this.previous.next.add(this);
                this.add_constraint(
                    new NodeConstraint(prv)
                );   
                new Connector(previous,this);
            } else {
                this.add_constraint(
                    new Clutter.BindConstraint(track, Clutter.BindCoordinate.Y,Track.SPACING)
                );
            }
            this.height = Node.HEIGHT;
            this.width = Node.HEIGHT;
            this.color = track.get_color().lighten();
            this.color = this.color.lighten();
            this.reactive = true;
            //this.motion_event.connect((x) => {return false;});

            this.favactor = new Clutter.Actor();
            this.favactor.height=this.favactor.width=FAVICON_SIZE;
            this.favactor.add_constraint (
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.POSITION, Node.HEIGHT/2-FAVICON_SIZE/2)
            );
            this.visible= false;
            this.bullet = new NodeBullet(this);
            this.highlight = new NodeHighlight(this);
            this.bullet.button_press_event.connect(do_button_press_event);
            this.transitions_completed.connect(do_transitions_completed);
            this.bullet.enter_event.connect(do_enter_event);
            this.bullet.leave_event.connect(do_leave_event);
            stage.add_child(this);
            stage.add_child(this.highlight);
            stage.add_child(this.bullet);
            stage.add_child(this.favactor);
            //this.track.get_last_track().recalculate_y(0);
        }

        private bool is_current_node = false;

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
            return true;
        }

        private bool do_leave_event(Clutter.CrossingEvent e) {
            if (!this.is_current_node) {
                this.highlight.save_easing_state();
                this.highlight.opacity = 0x00;
                this.highlight.restore_easing_state();
            }
            return true;
        }

        private void do_transitions_completed() {
            if (this.opacity == 0x00) {
                this.visible = false;
            }
        }

        public void set_favicon(Gdk.Pixbuf px) {
            var img = new Clutter.Image();
            img.set_data(px.get_pixels(),
                           px.has_alpha ? Cogl.PixelFormat.RGBA_8888 : Cogl.PixelFormat.RGB_888,
                           px.width,
                           px.height,
                           px.rowstride);
            this.favactor.content = img;
        }

        public void do_x_offset(GLib.Object t, ParamSpec p) {
            if (p.name == "x-offset") {
                this.x = this.xpos + (t as HistoryTrack).x_offset;
            }
        }
        
        private bool do_button_press_event(Clutter.ButtonEvent e) {
            if (e.button == Gdk.BUTTON_PRIMARY) {
                this.track.current_node = this;
                this.track.load_page(this);
                return true;
            } else {
                return false;
            }
        }

        private Node first_node() {
            return this.previous == null ? this : this.previous.first_node();
        }

        public int index_nextnode(Node n) {
            int i = 0;
            foreach (Node x in this.next) {
                if (x == n){
                    return i;
                }
                i++;
            }
            return 3;
        }

        public int get_splits() {
            int r = 0;
            foreach (Node n in this.next) {
                r += n.get_splits();
            }
            if (this.next.size > 1) {
                r += this.next.size - 1;
            }
            return r;
        }

        public void emerge() {
#if DEBUG
#else
            foreach (Node n in this.next) {
                n.emerge();
            }
            this.bullet.visible = true;
            this.bullet.save_easing_state();
            this.bullet.opacity = 0xE0;
            this.bullet.restore_easing_state();
            if (this.is_current_node) {
                this.highlight.visible = true;
                this.highlight.save_easing_state();
                this.highlight.opacity = 0xFF;
                this.highlight.restore_easing_state();
            }
#endif
        }

        public void disappear() {
#if DEBUG
#else
            foreach (Node n in this.next) {
                n.disappear();
            }
            this.bullet.save_easing_state();
            this.bullet.opacity = 0x00;
            this.bullet.restore_easing_state();
            this.highlight.save_easing_state();
            this.highlight.opacity = 0x000;
            this.highlight.restore_easing_state();
#endif
        }
    }
}
