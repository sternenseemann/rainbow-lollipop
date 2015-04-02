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
     * A UI-construct that is displayed in the Tracklist
     * It has two main purposes:
     *  1. Display a GtkEntry that enables the user to enter URLs or desired destinations
     *     in any other form and a "Go"-Button to cause the browser surfing to the given
     *     location.
     *  2. Display hints based on the input given in the url-entry mentioned in 1.
     */
    class EmptyTrack : Track {
        private Gtk.Entry url_entry;
        private Gtk.Button enter_button;
        private Gtk.Grid hbox;
        private GtkClutter.Actor actor; 
        private TrackList tracklist;

        /**
         * Returns a new Emtpy Track
         */
        public EmptyTrack(TrackList tl) {
            base(tl);
            this.tracklist = tl;
            this.url_entry = new Gtk.Entry();
            this.enter_button = new Gtk.Button.with_label(_("Go"));
            this.enter_button.clicked.connect(do_activate);
            this.hbox = new Gtk.Grid();
            this.hbox.add(this.url_entry);
            this.hbox.add(this.enter_button);
            this.url_entry.expand=true;
            this.url_entry.activate.connect(do_activate);
            this.url_entry.changed.connect(do_changed);
            this.actor = new GtkClutter.Actor.with_contents(this.hbox);
            this.actor.background_color = Clutter.Color.from_string(Config.c.colorscheme.empty_track);
            this.actor.height=26;
            this.actor.y = Config.c.track_height/2-this.actor.height/2;
            this.actor.x_expand=true;
            this.add_constraint(
                new Clutter.BindConstraint(tl, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.actor.transitions_completed.connect(do_transitions_completed);
            this.hbox.show_all();
            this.actor.visible = false;
            var boxlayout = new Clutter.BoxLayout();
            boxlayout.orientation = Clutter.Orientation.VERTICAL;
            this.set_layout_manager(boxlayout);
            this.add_child(this.actor);
            this.url_entry.realize.connect(() => {
                this.url_entry.grab_focus();
            });
        }

        /**
         * Add "http://" to a url, if it is not present
         * TODO: Use HTTPS-Everywhere API (eff.org somewhat) to add "https://" instead
         *       of "http://" wherever it is available
         * TODO: Add context menu for search fields, and retrieve shortcuts from database
         */
        private string complete_url(string url) {
            if (url.has_prefix("s ") || url.has_prefix("g "))
                return "https://duckduckgo.com/?q="+url.substring(2);
            if (url.has_prefix("wie "))
                return "https://en.wikipedia.org/wiki/Special:Search?search="+url.substring(3);
            if (url.has_prefix("wid "))
	        return "https://de.wikipedia.org/wiki/Special:Search?search="+url.substring(3);
            if (!url.has_prefix("http://") && !url.has_prefix("https://")) {
                return "http://" + url;
            }
            return url; 
        }

        /**
         * Callback that causes the browser to load the entered url in a new track
         * when enter is pressed in the URL entry
         */
        private void do_activate() {
            var url = this.complete_url(this.url_entry.get_text());
            this.tracklist.add_track_with_url(url);
            Application.S().state = NormalState.S();
        }

        /**
         * Callback that updates the displayed list of hints every time
         * The content of the URL-Entry changes.
         */
        private void do_changed() {
            //Order new hints from hintproviders based on entry-text
            var new_hints = new Gee.ArrayList<AutoCompletionHint>();
            string fragment = this.url_entry.get_text();
            if (fragment.length > 0){
                new_hints.add_all(DuckDuckGo.S().get_hints(fragment));
                new_hints.add_all(History.S().get_hints(fragment));
            }

            //Check which hints have to be dropped
            var to_delete = new Gee.ArrayList<AutoCompletionHint>();
            foreach (Clutter.Actor existing_hint in this.get_children()) {
                if (existing_hint != this.actor
                        && existing_hint is AutoCompletionHint
                        && !new_hints.contains((AutoCompletionHint)existing_hint)){
                    to_delete.add((AutoCompletionHint)existing_hint);
                }
            }

            // Add the new hints
            foreach (AutoCompletionHint new_hint in new_hints) {
                if (!this.contains(new_hint))
                    this.add_child(new_hint);
            }

            //Drop unnecessary hints
            foreach (AutoCompletionHint del_hint in to_delete) {
                this.remove_child(del_hint);
            }
        }

        /**
         * Erases any content from the URL entry
         */
        public void clear_urlbar(){
            this.url_entry.set_text("");
        }

        /**
         * Finishes a disappear-transition
         */
        private void do_transitions_completed() {
            if (this.actor.opacity == 0x00) {
                this.actor.visible=false;
            }
        }

        /**
         * Returns the needed height of this EmptyTrack
         * TODO: Check if really still necessary or if it would be better to use
         *       Clutter box-layouts.
         */
        public override int calculate_height(bool animated=true){
            return 26;
        }

        /**
         * Fade in
         */
        public override void emerge () {
            base.emerge();
            this.actor.visible = true;
            this.actor.save_easing_state();
            this.actor.opacity = 0xE0;
            this.actor.restore_easing_state();
            this.url_entry.grab_focus();
        }

        /**
         * Fade out
         */
        public override void disappear() {
            base.disappear();
            this.actor.save_easing_state();
            this.actor.opacity = 0x00;
            this.actor.restore_easing_state();
        }
    }

    /**
     * Every Class that wants to provide hints for the autocompletion of EmptyTrack
     * Must fulfill this interface.
     */
    interface IHintProvider {
        public abstract Gee.ArrayList<AutoCompletionHint> get_hints(string url);
    }

    /**
     * Represents an autocompletion hint for EmptyTrack
     */
    class AutoCompletionHint : Clutter.Actor {
        protected string heading = "";
        protected string text = "";
        protected Cairo.Surface icon = null;

        private Clutter.Text a_heading;
        private Clutter.Text a_text;
        private Clutter.Actor a_icon;
        private Clutter.Canvas a_icon_canvas;

        /**
         * This signal will be triggered when the user wants to actually
         * use this AutoCompletionHint. The actual logic must be specified
         * By the HintProvider that issued this AutoCompletionHint as callback
         * to this signal.
         */
        public signal void execute(TrackList tl);

        /**
         * Create an AutoCompletionHint with the given heading and text
         */
        public AutoCompletionHint(string heading, string text) {
            this.heading = heading;
            this.text = text;

            this.background_color = Clutter.Color.from_string(Config.c.colorscheme.tracklist);
            this.height = 115;
            this.x_expand = true;

            this.a_heading = new Clutter.Text.with_text("Sans 12", this.heading);
            this.a_heading.color=  Clutter.Color.from_string("#eeeeee");
            this.a_heading.x = 120;
            this.a_heading.y = 10;
            this.a_heading.height = 30;
            this.a_heading.x_expand = true;
            this.add_child(this.a_heading);

            this.a_text = new Clutter.Text.with_text("Sans 10", this.text);
            this.a_text.color=  Clutter.Color.from_string("#eeeeee");
            this.a_text.x = 120;
            this.a_text.y = 30;
            this.a_text.height = 30;
            this.a_text.x_expand = true;
            this.add_child(this.a_text);

            this.a_icon = new Clutter.Actor();
            this.a_icon.height=this.a_icon.width = 80;
            this.a_icon.x = 15;
            this.a_icon.y = 15;
            this.a_icon_canvas = new Clutter.Canvas();
            this.a_icon_canvas.set_size(80,80);
            this.a_icon_canvas.draw.connect(do_draw_icon);
            this.a_icon.content = this.a_icon_canvas;
            this.add_child(this.a_icon);
            this.a_icon_canvas.invalidate();

            this.reactive = true;
            var clickaction = new Clutter.ClickAction();
            clickaction.clicked.connect(this.trigger_execute);
            this.add_action(clickaction);
        }

        /**
         * Set the icon of this autocompletion hint
         */
        public void set_icon(Cairo.Surface px) {
            this.icon = px;
            this.a_icon_canvas.invalidate();
        }

        /**
         * Common logic that occurs every time when a user decides to use a
         * Completion hint. e.g. set the application state to normal browsing mode
         */
        public void trigger_execute(Clutter.Actor a){
            var tracklist = Application.S().tracklist;
            Application.S().state = NormalState.S();
            (this.get_parent() as EmptyTrack).clear_urlbar();
            this.execute(tracklist);
        }

        /**
         * Renders this AutoCompletionHint's icon
         * FIXME: only last entry has icon displayed, all entries are supposed to have one.
         */
        private bool do_draw_icon(Cairo.Context cr, int w, int h) {
            var fvcx = new Cairo.Context(this.icon);
            double x1,x2,y1,y2;
            fvcx.clip_extents(out x1,out y1,out x2,out y2);
            double width = x2-x1;
            double height = y2-y1;
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.scale(w/width,h/height);
            cr.set_source_surface(this.icon,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            return true;
        }
    }
}
