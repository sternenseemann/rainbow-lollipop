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
     * TrackListBackground is a half-transparent overlay over the WebViews
     * that optically emphasizes, that TrackList is a modal.
     */
    public class TrackListBackground : Clutter.Actor {
        /**
         * Construct a new TrackListBackground
         */
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

        /**
         * Fade in
         */
        public void emerge() {
            var tl = (TrackList)this.get_first_child();
            if (tl != null)
                tl.emerge();
            this.visible = true;
            this.save_easing_state();
            this.opacity = 0xE0;
            this.restore_easing_state();
        }

        /**
         * Fade out
         */
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

    /**
     * Represents a list of the currently opened HistoryTracks
     * The Tracklist also contains a special Track which is called
     * the EmptyTrack. The Empty Track offers users the possibility
     * To open new Websites
     */
    public class TrackList : Clutter.Actor {
        /**
         * Holds a reference to the currently active HistoryTrack
         * of this TrackList
         * The current_track is always the HistoryTrack that's associated
         * WebView is currently displayed in the foreground
         */
        public HistoryTrack? current_track {
            get {
                return this._current_track;
            }
            set {
                this._current_track = value;
            }
        }
        private HistoryTrack? _current_track;

        /**
         * Create a new TrackList
         */
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

        /**
         * Rebuild a tracklist from a JSON
         */
        public void from_json(Json.Node n){
            if (n.get_node_type() != Json.NodeType.ARRAY)
                stdout.printf("tracklist must be array\n");
            Json.Array arr = n.get_array();
            foreach (unowned Json.Node item in arr.get_elements()) {
                HistoryTrack t;
                try {
                    t = new HistoryTrack.from_json(this, item);
                    this.add_track(t);
                } catch (HistoryTrackError e) {
                    stdout.printf("track generation failed\n");
                }
            }
        }

        /**
         * Serialize this TrackList to JSON
         */
        public bool to_json(Json.Builder b) {
            b.begin_object();
            b.set_member_name("tracks");
            b.begin_array();
            bool valid = false;
            foreach (Clutter.Actor child in this.get_children()) {
                if (child is HistoryTrack) {
                    (child as HistoryTrack).to_json(b);
                    valid = true;
                }
            }
            b.end_array();
            b.end_object();
            return valid;
        }

        /**
         * Add the given HistoryTrack to this TrackList
         */
        private void add_track(HistoryTrack t) {
            this.insert_child_at_index(
                t,
                this.get_n_children()-1
            );
            (this.get_last_child() as Track).recalculate_y(true);
        }

        /**
         * Generate a new Track from the given url and add it to this
         * Tracklist
         */
        public void add_track_with_url(string url) {
            var t = new HistoryTrack(this, url);
            this.add_track(t);
        }

        /**
         * Generate a new Track from the given node and add it to
         *  this Tracklist
         */
        public void add_track_with_node(Node n) {
            var t = new HistoryTrack.with_node(this, (n as SiteNode));
            this.add_track(t);
        }

        /**
         * Returns the Track that the given Node belongs to
         * Returns null if no Track belongs to the given Node
         */
        public Track? get_track_of_node(Node n){
            foreach (Clutter.Actor t in this.get_children()) {
                if (t is HistoryTrack && (t as HistoryTrack).contains(n)) {
                    return (t as HistoryTrack);
                }
            }
            return null;
        }

        /**
         * Add an EmptyTrack to this TrackList
         */
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

        /**
         * Fade in
         */
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

        /**
         * Fade out
         */
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
