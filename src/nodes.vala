/*******************************************************************
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

using Gee;
using Math;

namespace RainbowLollipop {
    /**
     * Converts the 8bit representation of a color into a float between 0.0 and 1.0
     */
    private float col_h2f(uchar col) {
        return col/255.0f;
    }

    /**
     * A Constraint that keeps an area aligned to
     * the source's right border and the target's left border.
     * Used to assign an area to NodeConnectors
     */
    public class ConnectorConstraint : Clutter.Constraint {
        private Clutter.Actor source;
        private Clutter.Actor target;
        
        /**
         * Create a new node Connector from source to target
         */
        public ConnectorConstraint(Clutter.Actor source, Clutter.Actor target) {
            this.source=source;
            this.target=target;
        }

        /**
         * Updates the area depending on source's and target's positions
         */
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
            (a.content as Clutter.Canvas).set_size((int)roundf(alloc.x2-alloc.x1), (int)roundf(alloc.y2-alloc.y1));
        }
    }

    /**
     * An Actor that draws a connecting line between two nodes.
     * You can configure the connectors thickness with the config-entry 'connector_stroke'
     */
    public class Connector : Clutter.Actor {
        private Clutter.Canvas c;
        private Node previous;
        private Node next;

        /**
         * Create a new Connector from the Node previous to the Node next
         */
        public Connector(Node previous, Node next) {
            this.previous = previous;
            this.next = next;
            this.c = new Clutter.Canvas();
            this.content = c;
            this.set_size(10,10);
            this.c.set_size(10,10);
            this.x = Config.c.node_height/2+Config.c.track_spacing;
            this.y = 0;
            Config.c.notify.connect(config_update);
            this.c.draw.connect(do_draw);
            this.add_constraint(
                new ConnectorConstraint(previous, next)
            );
            this.c.invalidate();
            previous.track.add_nodeconnector(this);
            
        }

        /**
         * Handles changes in config
         */
        private void config_update() {
            this.x = Config.c.node_height/2+Config.c.track_spacing;
            this.queue_redraw();
        }

        /**
         * Draws the Connector line
         */
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

        /**
         * Fade in
         */
        public void emerge() {
            this.visible = true;
            this.save_easing_state();
            this.opacity = 0xFF;
            this.restore_easing_state();
        }

        /**
         * Fade out
         */
        public void disappear() {
            this.save_easing_state();
            this.opacity = 0x00;
            this.restore_easing_state();
        } 
    }


    /**
     * This class represents a Node. A node is a point in the history-tree
     * of a track. A node represents a call to a website and the result of
     * those calls.
     */
    public class Node : Focusable {
        /**
         * Reference to the node that spawned this node
         */
        private Node? previous;
        /**
         * Contains all nodes that have been spawned from this node
         */
        public Gee.ArrayList<Node> childnodes {get {return this._childnodes;}}
        private Gee.ArrayList<Node> _childnodes; //special list only for nodes
        /**
         * The HistoryTrack that this Node belongs to
         */
        public HistoryTrack track {get; set;}
        /**
         * The color in which this Node is displayed. The color is being derived
         * from the associated Track's color
         */
        public Clutter.Color color {get;set;}
        private Connector? connector;
        protected Clutter.ClickAction clickaction;

        /**
         * Constructs a node
         */
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
            this.height = this.width = Config.c.node_height;
            Config.c.notify.connect(config_update);
            this.color = track.get_background_color().lighten();
            this.color = this.color.lighten();
            this.previous.recalculate_y(null);
            this.reactive = true;
            this.clickaction = new Clutter.ClickAction();
            this.add_action(this.clickaction);

            Focus.S().focused_object = this;
        }

        protected virtual void config_update() {
            this.height = this.width = Config.c.node_height;
            this.x = this.previous.x+this.previous.width+(float)Config.c.node_spacing;
            this.y = Config.c.track_spacing;
            this.queue_redraw();
            this.previous.recalculate_y(null);
        }

        /**
         * Declares this node a rootnode by removing the reference to any previous Node
         */
        public void make_root_node() {
            this.previous = null; 
        }

        /**
         * Takes this node an all its childnodes, creates a new track, removes said
         * nodes from their current track and assigns them to the newly created track
         */
        public void move_to_new_track() {
            SiteNode? new_track_current_node = null;
            string new_track_search_string = "";
            var prv = this.previous;
            if (prv != null) {
                bool need_new_current_node = this.contains_current_node();
                prv.childnodes.remove(this);
                prv.recalculate_y(null);
                prv.track.calculate_height();
                if (need_new_current_node) {
                    new_track_current_node = this.track.current_node as SiteNode;
                    new_track_search_string = this.track.web.get_search_string(); 
                    this.track.web.stop_search();
                    if (prv is SiteNode)
                        prv.track.current_node = prv as SiteNode;
                }
            } else {
                this.track.delete_track();
            }
            this.get_parent().remove_child(this);
            this.connector.destroy();
            this.detach_childnodes();
            this.track.tracklist.add_track_with_node(this, 
                                                     new_track_current_node, 
                                                     new_track_search_string);
        }

        /**
         * Returns the Index in the childnodes-list of the given child-node
         */
        private int index_of_child(Node n) {
            return this.childnodes.index_of(n);
        }

        /**
         * Returns, into how many side-branches this node holds
         * (in general the number of children-1) except when the
         * node has only one child.
         * This is used to calculate how much offset a node must have in order
         * to render a proper non-entangled graphical tree representation
         */
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

        /**
         * Returns how many splits there are until the given childnode-index
         */
        public int get_splits_until(int index) {
            int r = 0;
            for (int i = 0; i < index; ++i) {
                r += (this.childnodes.get(i) as Node).get_splits();
            }
            return r;
        }

        /**
         * Determines whether the subtree under this node contains the
         * current_node of the track.
         */
        public bool contains_current_node() {
            foreach (Node n in this.childnodes) {
                if (n == this.track.current_node || n.contains_current_node()) {
                    return true;
                }
            }
            return false; 
        }

        /**
         * Takes care of recursively deleting this node and all child nodes.
         * Causes this Node's track to recalculate its height and rerender
         * the node-tree.
         */
        public void delete_node(bool rec_initial=true) {
            bool need_new_current_node = false;
            if (rec_initial) {
                need_new_current_node = this.contains_current_node();
            }
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
                if (prv == null) {
                    //This was the root node. the track is not necessary anymore, delete it.
                    this.track.delete_track();
                } else {
                    //Recalculate the tracks height in case there is some free space now
                    this.track.calculate_height();
                    if (need_new_current_node && prv is SiteNode) {
                        this.track.current_node = prv as SiteNode;
                    }
                }
            }
        }

        /**
         * Handles right-clicking on a node
         */
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

        /**
         * Lets each childnode of this node recalculate its y-coordinate positions
         */
        public void recalculate_nodes() {
            foreach (Node n in this.childnodes) {
                n.recalculate_y(this);
            }
        }

        /**
         * Recalculates this Node's y-coordinate position for the graphical tree
         * representation.
         */
        public void recalculate_y(Node? call_origin) {
            if (this.previous != null && call_origin != this.previous) {
                this.previous.recalculate_y(this);
                return;
            } else {
                int node_index = this.previous.index_of_child((Node) this);
                if (node_index == -1)
                    warning(_("The node is not a child of its parent. This should not happen"));
                int splits_until = this.previous.get_splits_until(node_index);
                var prvy = this.previous.y != 0 ? this.previous.y : Config.c.track_spacing;
                this.y =  prvy + (splits_until+node_index)*(Config.c.node_height+Config.c.track_spacing);
                foreach (Node n in this.childnodes) {
                    n.recalculate_y(this);
                }
            }
        }

        /**
         * Returns this Node's previous node if any.
         * If it returns null, this node is a root node.
         */
        public Node? get_previous() {
            return this.previous;
        }

        /**
         * Deletes any reference to this node from a parent node and destroys
         * the Connector that connects the two.
         */
        private void detach_childnodes() {
            foreach (Node n in this.childnodes) {
                n.detach_childnodes();
            }
            this.get_parent().remove_child(this);
            this.connector.destroy();
        }

        /**
         * Ensures that this Node and its Connector have colors according to their Track
         */
        protected void adapt_to_track() {
            if (this.previous != null) {
                this.connector = new Connector(this.previous, this);
            }
        }

        /**
         * Serialize this nodes and its childnodes recursively into JSON
         */
        public void to_json(Json.Builder b) {
            b.set_member_name("nodes");
            b.begin_array();
            foreach (Node n in this.childnodes) {
                if (n is SiteNode)
                    (n as SiteNode).to_json(b);
            }
            b.end_array();
        }

        /**
         * Tries to return the next sibling that resides on the
         * same tree-depth as this node.
         */
        public Node? get_next_on_same_level(Node node, uint level=0) {
            if (this.childnodes.size > this.index_of_child(node)+1) {
                Node n = this.childnodes[this.index_of_child(node)+1];
                for (int i = 0; i < level; i++) {
                    if (n.childnodes.size > 0)
                        n = n.childnodes[0];
                    else
                        return null;
                }
                return n;
            } else {
                if (this.previous != null)
                    return this.previous.get_next_on_same_level(this, ++level);
                else
                    return null;
            }
        }

        /**
         * Tries to return the previous sibling that resides on the
         * same tree-depth as this node.
         */
        public Node? get_previous_on_same_level(Node node, uint level=0) {
            if (this.index_of_child(node) > 0) {
                Node n = this.childnodes[this.index_of_child(node)-1];
                for (int i = 0; i < level; i++) {
                    if (n.childnodes.size > 0)
                        n = n.childnodes[n.childnodes.size-1];
                    else
                        return null;
                }
                return n;
            } else {
                if (this.previous != null)
                    return this.previous.get_previous_on_same_level(this, ++level);
                else
                    return null;
            }
        }

        public override Focusable? get_left_focusable() {
            return this.previous;
        }

        public override Focusable? get_right_focusable() {
            if (this.childnodes.size > 0)
                return this.childnodes[0];
            else
                return null;
        }

        public override Focusable? get_down_focusable() {
            Node? n = this.previous.get_next_on_same_level(this);
            if (n != null)
                return n;
            else {
                Track? t = (this.track.get_next_sibling() as Track);
                if (t != null && t is HistoryTrack) {
                    return (t as HistoryTrack).current_node;
                } else {
                    return Application.S().tracklist.get_empty_track().get_go_button();
                }
            }
        }

        public override Focusable? get_up_focusable() {
            Node? n = this.previous.get_previous_on_same_level(this);
            if (n != null)
                return n;
            else {
                Track? t = (this.track.get_previous_sibling() as Track);
                if (t != null && t is HistoryTrack) {
                    return (t as HistoryTrack).current_node;
                } else
                    return null;
            }
        }

        public override void focus_activate() {
            if (this is SiteNode) {
                this.track.current_node = this;
                Application.S().state = NormalState.S();
            }
        }
    }
}
