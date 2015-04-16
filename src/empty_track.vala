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
    public class EmptyTrack : Track {
        private Gtk.Entry url_entry;
        private GtkClutter.Actor actor; 
        private TrackList tracklist;

        private Clutter.Actor listcontainer;
        private Clutter.BoxLayout lc_boxlayout;
        private Focusable surf_directly_to;
        private Clutter.Actor search_hints;
        private Clutter.BoxLayout sh_boxlayout;
        private Clutter.Actor history_hints;
        private Clutter.BoxLayout hh_boxlayout;

        public const int HINT_HEIGHT = 40;

        /**
         * Returns a new Emtpy Track
         */
        public EmptyTrack(TrackList tl) {
            base(tl);
            this.tracklist = tl;
            this.url_entry = new Gtk.Entry();
            this.url_entry.expand=true;
            this.url_entry.changed.connect(do_changed);
            this.actor = new GtkClutter.Actor.with_contents(this.url_entry);
            //this.actor.background_color = Clutter.Color.from_string(Config.c.colorscheme.empty_track);
            this.actor.height=26;
            this.actor.y = Config.c.track_height/2-this.actor.height/2;
            this.actor.x_expand=true;
            this.add_constraint(
                new Clutter.BindConstraint(tl, Clutter.BindCoordinate.WIDTH, 0)
            );
            this.actor.transitions_completed.connect(do_transitions_completed);
            this.actor.visible = false;
            var boxlayout = new Clutter.BoxLayout();
            boxlayout.orientation = Clutter.Orientation.VERTICAL;
            boxlayout.spacing = 5;
            this.set_layout_manager(boxlayout);
            this.add_child(this.actor);
            this.url_entry.realize.connect(() => {
                this.url_entry.grab_focus();
            });

            // Initialize listcontainer the listcontainer contains the lists
            this.listcontainer = new Clutter.Actor();
            this.lc_boxlayout = new Clutter.BoxLayout();
            this.lc_boxlayout.orientation = Clutter.Orientation.HORIZONTAL;
            this.lc_boxlayout.spacing = 5;
            this.lc_boxlayout.homogeneous = true;
            this.listcontainer.x_expand = true;
            this.listcontainer.set_layout_manager(this.lc_boxlayout);
            this.listcontainer.add_constraint(
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.WIDTH,0)
            );

            // Add surf directly to - button
            this.surf_directly_to = new SurfDirectlyToButton();
            this.listcontainer.add_child(this.surf_directly_to);
            
            // Add search hint list
            this.search_hints = new Clutter.Actor();
            this.sh_boxlayout = new Clutter.BoxLayout();
            this.sh_boxlayout.orientation = Clutter.Orientation.VERTICAL;
            this.sh_boxlayout.spacing = 5;
            this.search_hints.set_layout_manager(this.sh_boxlayout);
            /*this.search_hints.background_color = Clutter.Color.from_string(
                "#00ff00" 
            );*/
            this.search_hints.height = HINT_HEIGHT;
            this.search_hints.x_expand = true;
            this.listcontainer.add(this.search_hints);
            

            // Add history hint list
            this.history_hints = new Clutter.Actor();
            this.hh_boxlayout = new Clutter.BoxLayout();
            this.hh_boxlayout.orientation = Clutter.Orientation.VERTICAL;
            this.hh_boxlayout.spacing = 5;
            /*this.history_hints.background_color = Clutter.Color.from_string(
                "#ff0000"
            );*/
            this.history_hints.height = HINT_HEIGHT;
            this.history_hints.x_expand = true;
            this.history_hints.set_layout_manager(this.hh_boxlayout);
            this.listcontainer.add(this.history_hints);


    
            this.add_child(this.listcontainer);
        }

        /**
         * Add "http://" to a url, if it is not present
         * TODO: Add context menu for search fields, and retrieve shortcuts from database
         */
        private string complete_url(string p_url) {
            string url = p_url;
            url = url.strip();
            if (url.has_prefix("s ") || url.has_prefix("g "))
                return "https://duckduckgo.com/?q="+url.substring(2);
            if (url.has_prefix("wie "))
                return "https://en.wikipedia.org/wiki/Special:Search?search="+url.substring(3);
            if (url.has_prefix("wid "))
                return "https://de.wikipedia.org/wiki/Special:Search?search="+url.substring(3);
            if (!url.has_prefix("http://") && !url.has_prefix("https://")) {
                url = "http://" + url;
            }
            if (Config.c.https_everywhere) {
                return HTTPSEverywhere.rewrite(url);
            }
            return url; 
        }

        /**
         * Returns the surf_directly_to button for focussing
         */
        public Focusable get_go_button() {
            return this.surf_directly_to;
        }

        /**
         * Callback that causes the browser to load the entered url in a new track
         * when enter is pressed in the URL entry
         */
        public void do_activate() {
            var url = this.complete_url(this.url_entry.get_text());
            this.tracklist.add_track_with_url(url);
            Application.S().state = NormalState.S();
        }

        /**
         * Callback that updates the displayed list of hints every time
         * The content of the URL-Entry changes.
         */
        private void do_changed() {
            Focus.S().focused_object = this.surf_directly_to;
            //Order new hints from hintproviders based on entry-text
            var provided_search_hints = new Gee.ArrayList<AutoCompletionHint>();
            var provided_history_hints = new Gee.ArrayList<AutoCompletionHint>();
            string fragment = this.url_entry.get_text();
            if (fragment.length > 0){
                provided_search_hints.add_all(DuckDuckGo.S().get_hints(fragment));
                provided_search_hints.add_all(Wikipedia.S().get_hints(fragment));
                provided_history_hints.add_all(History.S().get_hints(fragment));
            }

            //Check which hints have to be dropped
            var search_hints_to_delete = new Gee.ArrayList<AutoCompletionHint>();
            var history_hints_to_delete = new Gee.ArrayList<AutoCompletionHint>();
            foreach (Clutter.Actor existing_hint in this.search_hints.get_children()) {
                if (!provided_search_hints.contains((AutoCompletionHint)existing_hint)){
                    search_hints_to_delete.add((AutoCompletionHint)existing_hint);
                }
            }
            foreach (Clutter.Actor existing_hint in this.history_hints.get_children()) {
                if (!provided_history_hints.contains((AutoCompletionHint)existing_hint)){
                    history_hints_to_delete.add((AutoCompletionHint)existing_hint);
                }
            }

            // Add the new hints
            foreach (AutoCompletionHint new_hint in provided_search_hints) {
                if (!this.search_hints.contains(new_hint))
                    this.search_hints.add_child(new_hint);
            }
            foreach (AutoCompletionHint new_hint in provided_history_hints) {
                if (!this.history_hints.contains(new_hint))
                    this.history_hints.add_child(new_hint);
            }

            //Drop unnecessary hints
            foreach (AutoCompletionHint del_hint in search_hints_to_delete) {
                this.search_hints.remove_child(del_hint);
            }
            foreach (AutoCompletionHint del_hint in history_hints_to_delete) {
                this.history_hints.remove_child(del_hint);
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
    class AutoCompletionHint : Focusable {
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
            this.height = EmptyTrack.HINT_HEIGHT;
            this.x_expand = true;

            this.a_heading = new Clutter.Text.with_text("Sans 10", this.heading);
            this.a_heading.color=  Clutter.Color.from_string("#eeeeee");
            this.a_heading.x = 40;
            this.a_heading.y = 10;
            this.a_heading.height = 30;
            this.a_heading.x_expand = true;
            //this.add_child(this.a_heading);

            this.a_text = new Clutter.Text.with_text("Sans 8", this.text);
            this.a_text.color=  Clutter.Color.from_string("#eeeeee");
            this.a_text.x = 40;
            this.a_text.y = 10;
            this.a_text.height = 30;
            this.a_text.x_expand = true;
            this.add_child(this.a_text);

            this.a_icon = new Clutter.Actor();
            this.a_icon.height=this.a_icon.width = 30;
            this.a_icon.x = 5;
            this.a_icon.y = 5;
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
        public void trigger_execute(){
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

        public override Focusable? get_left_focusable() {
            Clutter.Actor next_list = this.get_parent().get_previous_sibling();
            if (next_list == null || next_list.get_n_children() == 0)
                return null;
            if (next_list.first_child is Focusable)
                return next_list.first_child as Focusable;
            else
                // Return the surf directly to button
                return Application.S().tracklist.get_empty_track().get_go_button();
        }

        public override Focusable? get_right_focusable() {
            Clutter.Actor next_list = this.get_parent().get_next_sibling();
            if (next_list == null || next_list.get_n_children() == 0)
                return null;
            if (next_list.first_child is Focusable)
                return next_list.first_child as Focusable;
            else
                return null;
        }

        public override Focusable? get_up_focusable() {
            Clutter.Actor? a = this.get_previous_sibling();
            if (a != null && a is AutoCompletionHint) {
                return (a as AutoCompletionHint);
            } else {
                HistoryTrack? t = Application.S().tracklist.get_last_track();
                if (t != null)
                    return t.current_node;
                else
                    return null;
            }
        }

        public override Focusable? get_down_focusable() {
            Clutter.Actor? a = this.get_next_sibling();
            if (a != null && a is AutoCompletionHint) {
                return (a as AutoCompletionHint);
            } else
                return null;
        }

        public override void focus_activate() {
            this.trigger_execute();
        }
    }
    
    class SurfDirectlyToButton : Focusable {
        private Clutter.Text a_text;
        public SurfDirectlyToButton() {
            this.background_color = Clutter.Color.from_string(
                Config.c.colorscheme.tracklist
            );
            this.height = EmptyTrack.HINT_HEIGHT;
            this.width = 100;
            this.x_expand = true;
            this.reactive=true;
            var surf_action = new Clutter.ClickAction();
            this.add_action(surf_action);
            surf_action.clicked.connect(()=>{
                (this.get_parent().get_parent() as EmptyTrack).do_activate();
            });
            this.a_text = new Clutter.Text.with_text("Sans 15", _("Go"));
            this.a_text.color=  Clutter.Color.from_string("#eeeeee");
            this.a_text.x = 10;
            this.a_text.y = 10;
            this.a_text.height = 30;
            this.a_text.x_expand = true;
            this.add_child(this.a_text);
        }

        public override Focusable? get_left_focusable() {
            return null;
        }

        public override Focusable? get_right_focusable() {
            Clutter.Actor next_list = this.get_next_sibling();
            if (next_list == null || next_list.get_n_children() == 0)
                return null;
            if (next_list.first_child is Focusable)
                return next_list.first_child as Focusable;
            else
                return null;
        }

        public override Focusable? get_up_focusable() {
            HistoryTrack? t = Application.S().tracklist.get_last_track();
            if (t != null)
                return t.current_node;
            else
                return null;
        }

        public override Focusable? get_down_focusable() {
            return null;
        }

        public override void focus_activate() {
            (this.get_parent().get_parent() as EmptyTrack).do_activate();
        }
    }
}
