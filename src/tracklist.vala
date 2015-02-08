namespace alaia {
    public class TrackListBackground : Clutter.Actor {
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

    public class TrackList : Clutter.Actor {
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

        //TODO: write constructor that builds tracklist from json

        public void to_json(Json.Builder b) {
            b.begin_object();
            b.set_member_name("tracks");
            b.begin_array();
            foreach (Clutter.Actor child in this.get_children()) {
                if (child is HistoryTrack) {
                    (child as HistoryTrack).to_json(b);
                }
            }
            b.end_array();
            b.end_object();
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
            var t = new HistoryTrack.with_node(this, (n as SiteNode));
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
