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
     * Extended Version of WebKit's WebView which is able to store
     * a reference to a HistoryTrack along with it and offers methods
     * to communicate with the web-extension-process of this view.
     */
    public class TrackWebView : WebKit.WebView {
        /**
         * Stores a reference to the HistoryTrack that is associated with
         * this WebView
         */
        public HistoryTrack track{ get;set; }
        private SearchWidget search;
        private bool searchstate;

        private string? _last_link = "";
        public string? last_link {get { return this._last_link; }}

        /**
         * Creates a new WebView for rainbow-lollipop
         */
        public TrackWebView(Clutter.Actor webactor) {
            this.search = new SearchWidget(webactor, this.get_find_controller());
            webactor.add_child(this.search);
            this.button_press_event.connect(do_button_press_event);
            this.mouse_target_changed.connect(do_mouse_target_changed);
        }

        /**
         * Remembers the last button that has been pressed down on the mouse
         * This is used to determine wheter a link has been clicked with a
         * left mousebutton or with the middle mousebutton, so we can open
         * links as new nodes. 
         *
         * Handles mouse events that we need to override webkits default behaviour
         * for. At the moment these are:
         *  - Links being clicked with the middle mousebutton
         *  - Links being clicked regularly with the left mousebutton
         *    TODO: find out if this is really necessary some time. It works and
         *          fixes issue #57 but i find it a bit cumbersome
         */
        public bool do_button_press_event(Gdk.EventButton e) {
            if (e.button == Gdk.BUTTON_MIDDLE && this._last_link != null) {
                this.track.log_call(this._last_link, false);
                return true;
            }
            else if (e.button == Gdk.BUTTON_PRIMARY && this._last_link != null
                                                    && this._last_link != "") {
                this.load_uri(this._last_link);
                return true;
            }
            return false;
        }

        /**
         * Remembers the last link that the user hovered over
         */
        public void do_mouse_target_changed(WebKit.HitTestResult htr, uint modifiers) {
            this._last_link = htr.link_uri;
        }

        /**
         * Asks The web-extension-process whether this webview currently
         * needs input from the keyboard e.g. to fill content into a
         * HTML form-element.
         */
        public async void needs_direct_input(IPCCallback cb, Gdk.EventKey e) {
            ZMQVent.needs_direct_input(this, cb, e);
        }

        /**
         * Asks the web-extension for information about the scroll position of the
         * current_page
         */
        public async void get_scroll_info(IPCCallback cb) {
            ZMQVent.get_scroll_info(this,cb);
        }

        /**
         * Tells the webviews webprocess to scroll to the given positionö
         */
        public async void set_scroll_info(long x, long y) {
            ZMQVent.set_scroll_info(this, x, y);
        }

        /**
         * Returns true if the searchoverlay is currently active for this webview
         */
        public bool is_search_active() {
            return this.searchstate;
        }

        /**
         * Shows up the search dialog
         */
        public void start_search(string search_string="") {
            this.search.visible = this.searchstate = true;
            this.search.set_search_string(search_string);
        }

        /**
         * Returns the current search string
         */
        public string get_search_string() {
            return this.search.get_search_string();
        }

        /**
         * Shuts down the search overlay
         */
        public void stop_search() {
            this.searchstate = false;
        }

        /**
         * Hides the search overlay
         */
        public void hide_search() {
            this.search.visible = false;
        }

        /**
         * Shows the search overlay if there is currently a search going on
         */
        public void restore_search() {
            this.search.visible = this.searchstate;
        }
    }
}
