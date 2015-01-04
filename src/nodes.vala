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

    public class ConnectorConstraint : Clutter.Constraint {
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
    
    public class Connector : Clutter.Actor {
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


    public class Node : Clutter.Actor {
        private Node? previous;
        private Gee.ArrayList<Node> _childnodes; //special list only for nodes
        public Gee.ArrayList<Node> childnodes {get {return this._childnodes;}}
        public HistoryTrack track {get; set;}
        public Clutter.Color color {get;set;}
        private Connector? connector;
        protected Clutter.ClickAction clickaction;

        public Node(HistoryTrack track, Node? par) {
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
            this.previous.recalculate_y(null);
            this.reactive = true;
            this.clickaction = new Clutter.ClickAction();
            this.add_action(this.clickaction);
        }

        public void make_root_node() {
            this.previous = null; 
        }

        public void move_to_new_track() {
            var prv = this.previous;
            if (prv != null) {
                prv.childnodes.remove(this);
                prv.recalculate_y(null);
                (prv.track.get_parent().get_last_child() as Track).recalculate_y(true);
            }
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

        public void do_clicked() {
            switch (this.clickaction.get_button()) {
                case 3: //Right mousebutton
                    Application.S().context.set_context(this.track,this);
                    Application.S().context.popup(null,null,null,3,0);
                    break;
            }
            this.track.clickaction.release(); //TODO: ugly fix.. there has to be a better way
                                              // Prevents nodes from hanging in a pressed
                                              // state after they have been clicked.
        }

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

        protected void adapt_to_track() {
            if (this.previous != null) {
                this.connector = new Connector(this.previous, this);
            }
        }

    }
}
