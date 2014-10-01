using Gee;

namespace alaia {
    class Node : Clutter.Rectangle {
        public static const uint8 COL_MULTIPLIER = 15;
        private Gee.ArrayList<Node> next;
        private Node? previous;
        private HistoryTrack track;
        private Clutter.Actor stage;

        private string _url;

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
            this.stage = stage;
            this.x = 100;
            if (prv != null){
                this.x = prv.x;
                this.save_easing_state();
                this.x = prv.x+100;
                this.restore_easing_state();
            }
            this.height = 75;
            this.width = 75;
            this.color = track.get_color().lighten();
            this.color = this.get_color().lighten();
            this.add_constraint(
                new Clutter.BindConstraint(track, Clutter.BindCoordinate.Y,37)
            );
            this.button_press_event.connect(do_button_press_event);
            stage.add_child(this);
        }
    
        private bool do_button_press_event(Clutter.ButtonEvent e) {
            stdout.printf("beenis\n");
            this.track.current_node = this;
            return true;
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
    }

}
