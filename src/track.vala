using WebKit;

namespace alaia {
    /**
     * This class provides colors for newly created tracks.
     * By iterating through a list of colors that is specified
     * by the currently active Colorscheme in the current Config
     */
    class TrackColorSource : GLib.Object {
        private static Gee.ArrayList<string> colors;
        private static int state = 0;
        private static bool initialized = false;

        /**
         * Initialize
         */
        public static void init() {
            if (!TrackColorSource.initialized) {
                TrackColorSource.colors = new Gee.ArrayList<string>();
                foreach (string color in Config.c.colorscheme.tracks) {
                    TrackColorSource.colors.add(color);
                }
                TrackColorSource.initialized = true;
            }
        }

        /**
         * Returns a Clutter.Color from the palette of colors defined in the
         * colorscheme under the array "tracks"
         */
        public static Clutter.Color get_color() {
            TrackColorSource.init();
            var color = TrackColorSource.colors.get(TrackColorSource.state);
            if (++TrackColorSource.state == TrackColorSource.colors.size) {
                TrackColorSource.state = 0;
            }
            return Clutter.Color.from_string(color);
        }
    }

    /**
     * Abstact superclass for Tracks that can be kept in a TrackList
     */
    public abstract class Track : Clutter.Actor {
        /**
         * Construct a new Track
         */
        public Track(TrackList tl) {
            Track last_track = (tl.get_last_child() as Track);
            if (last_track != null) {
                this.y = last_track.y;
                this.save_easing_state();
                this.restore_easing_state();
            }
            this.add_constraint(
                new Clutter.BindConstraint(tl, Clutter.BindCoordinate.WIDTH, 0)
            );


            this.opacity = Application.S().state == AppState.TRACKLIST ? Config.c.track_opacity : 0x00;
            this.visible = Application.S().state == AppState.TRACKLIST;

            this.transitions_completed.connect(do_transitions_completed);
            this.background_color = TrackColorSource.get_color();
            this.height = this.calculate_height();
            (this.get_parent().get_last_child() as Track).recalculate_y(true);
        }

        /**
         * Cause other tracks to recalculate their y positions when this Track is
         * being deleted.
         */
        ~Track(){
            (this.get_parent().get_last_child() as Track).recalculate_y(true);
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
            this.visible = true;
            this.save_easing_state();
            this.opacity = Config.c.track_opacity;
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

        /**
         * Delete this track
         */
        public bool delete_track () {
            Track par = (Track)this.get_parent().get_last_child();
            this.destroy();
            par.recalculate_y();
            return false;
        }

        /**
         * Method that calculates the height that this Track currently needs
         */
        protected abstract int calculate_height();

        /**
         * Recalculate the y-position of this track
         */
        public int recalculate_y(bool animated=true){
            var previous = (this.get_previous_sibling() as Track);

            if (animated) 
                this.save_easing_state();

            var ypos = this.y = previous != null ? previous.recalculate_y(animated) : 0;

            if (animated)
                this.restore_easing_state();

            return this.calculate_height() + (int)ypos;
        }
    }
}
