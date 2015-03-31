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

namespace RainbowLollipop {
    /**
     * This Interface must be implemented by every class that
     * represents an application state.
     * Application states are mutually exclusive, so only
     * one application state can be active at a time.
     * Application states are singleton classes.
     */
    interface IApplicationState : GLib.Object {
        public abstract void enter();
        public abstract void leave();
    }

    /**
     * NORMAL - Browsing mode. Screen space is occupied by a WebView
     */
    class NormalState : GLib.Object, IApplicationState {
        private static NormalState instance = null;
        private static bool initialized = false;

        private Clutter.Actor webactor = null;
        private Clutter.BlurEffect blur = null;
        private Clutter.DesaturateEffect desaturate = null;

        public static void init (Clutter.Actor webact) {
            NormalState.instance = new NormalState(webact);
            NormalState.initialized = true;
        }

        private NormalState(Clutter.Actor webact) {
            this.webactor = webact;
            this.blur = new Clutter.BlurEffect();
            this.desaturate = new Clutter.DesaturateEffect(1.0d);
        }

        public void enter() {
            this.webactor.remove_effect(this.blur);
            this.webactor.remove_effect(this.desaturate);
        }

        public void leave() {
            this.webactor.add_effect(this.blur);
            this.webactor.add_effect(this.desaturate);
        }

        public static IApplicationState S() {
            if (!NormalState.initialized)
                critical(_("NormalState has not been initialized."));
            return NormalState.instance;
        }
    }

    /**
     * TRACKLIST - WebViews are overlayed by a list of Tracks
     */
    class TracklistState : GLib.Object, IApplicationState {
        private static TracklistState instance = null;
        private static bool initialized = false;

        private TrackListBackground tracklist_background = null;

        public static void init (TrackListBackground tlb) {
            TracklistState.instance = new TracklistState(tlb);
            TracklistState.initialized = true;
        }

        private TracklistState(TrackListBackground tlb) {
            this.tracklist_background = tlb;
        }

        public void enter() {
            this.tracklist_background.emerge();
        }

        public void leave() {
            this.tracklist_background.disappear();
        }

        public static IApplicationState S() {
            if (!TracklistState.initialized)
                critical(_("TracklistState has not been intialized."));
            return TracklistState.instance;
        }
    }

    /**
     * SESSIONDIALOG - Screen is occupied by a restore-session-dialog
     */
    class SessiondialogState : GLib.Object, IApplicationState {
        private static SessiondialogState instance = null;
        private static bool initialized = false;

        private RestoreSessionDialog session_dialog = null;

        public static void init (RestoreSessionDialog sd) {
            SessiondialogState.instance = new SessiondialogState(sd);
            SessiondialogState.initialized = true;
        }

        private SessiondialogState(RestoreSessionDialog sd) {
            this.session_dialog = sd;
        }

        public void enter() {
            this.session_dialog.emerge();
        }

        public void leave() {
            this.session_dialog.disappear();
        }

        public static IApplicationState S() {
            if (!SessiondialogState.initialized)
                critical(_("SessiondialogState has not been intialized."));
            return SessiondialogState.instance;
        }
    }
}
