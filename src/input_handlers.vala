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
     * Enumerates the available inputHandlers
     */
    enum InputHandlerType {
        DEFAULT=0,
        VIM=1,
        TABLET=2 
    }
    /**
     * handles the incoming keypresses
     * on the application.
     */
    interface IInputHandler : GLib.Object {
        /**
         * First Callback an occurring key-event will pass through
         * This method will determine, wheter it is necessary to obtain any further
         * information from web-extension-procecsses.
         * Further it will determine wheter the occurred event is relevant for the
         * current application state and drop it, if not so.
         *
         * If there is no necessity to obtain further information from the
         * web-extensions, the event will be plainly forwarded to
         * do_key_press_event(Gdk.EventKey e)
         *
         * If it is necessary, it will forward the need for information by calling
         * an appropriate method of TrackWebView and passing do_key_press_event(Gdk.EventKey e)
         * as callback and the incoming Gdk.EventKey e.
         * the method of TrackWebView will call do_key_press_event eventually in an asnychronous
         * manner
         */
        public abstract bool preprocess_key_press_event(Gdk.EventKey e);
        /**
         * This method executes actions according to an incoming preprocessed
         * Gdk.EventKey e (See preprocess_key_press_event(Gdk.EventKey e) for furhter info)
         * The action that will be taken is depending on which state the application
         * is currently in.
         */
        public abstract void do_key_press_event(Gdk.EventKey e);
    }

    /**
     * This class defines an inputscheme similar to those of the vim-editor
     * or the vimperator plugin for mozilla
     */
    class VimInputHandler : GLib.Object, IInputHandler {
        /**
         * TODO: implement
         */
        public bool preprocess_key_press_event(Gdk.EventKey e) {
            do_key_press_event(e);
            return false;
        }
        /**
         * TODO: implement
         */
        public void do_key_press_event(Gdk.EventKey e) {
        }
    }

    /**
     * This class defines an inputscheme suited for tablets
     * or the vimperator plugin for mozilla
     */
    class TabletInputHandler : GLib.Object, IInputHandler {
        /**
         * TODO: implement
         */
        public bool preprocess_key_press_event(Gdk.EventKey e) {
            do_key_press_event(e);
            return false;
        }
        /**
         * TODO: implement
         */
        public void do_key_press_event(Gdk.EventKey e) {
        }
    }

    /**
     * This class defines an inputscheme similar to those of the vim-editor
     * or the vimperator plugin for mozilla
     */
    class DefaultInputHandler : GLib.Object, IInputHandler {
        public void do_key_press_event_wrap(GLib.Value[] v) {
            Gdk.EventKey e = v[0] as Gdk.EventKey;
            this.do_key_press_event(e);
        }

        public bool preprocess_key_press_event(Gdk.EventKey e) {
            if (Application.S().state is NormalState) {
                var t = Application.S().tracklist.current_track;
                var twv = Application.S().get_web_view(t) as TrackWebView;
                switch(e.keyval) {
                    case Gdk.Key.F2:
                        do_key_press_event(e);
                        break;
                    case Gdk.Key.Tab:
                        if (t != null)
                            twv.needs_direct_input(do_key_press_event_wrap,e);
                        else
                            do_key_press_event(e);
                        break;
                    default:
                        if (twv.is_search_active()) {
                            return false;
                        }
                        do_key_press_event(e);
                        break;
                }
            }
            else if (Application.S().state is TracklistState) {
                if (e.keyval !=    Gdk.Key.Tab
                    && e.keyval != Gdk.Key.F2
                    && e.keyval != Gdk.Key.Down
                    && e.keyval != Gdk.Key.Up
                    && e.keyval != Gdk.Key.Left
                    && e.keyval != Gdk.Key.Right
                    && e.keyval != Gdk.Key.Return)
                        return false;
                do_key_press_event(e);
            }
            else if (Application.S().state is SessiondialogState) {
                if (e.keyval !=    Gdk.Key.Left
                    && e.keyval != Gdk.Key.Right
                    && e.keyval != Gdk.Key.Return)
                    return false;
                do_key_press_event(e);
            }
            else if (Application.S().state is ConfigState) {
                if (e.keyval !=    Gdk.Key.Escape
                    && e.keyval != Gdk.Key.Tab)
                    return false;
                do_key_press_event(e);
            }
            else if (Application.S().state is AuthState) {
                return false;
            }
            return true;
        }

        public void do_key_press_event(Gdk.EventKey e) {
            if (Application.S().state is NormalState) {
                var t = Application.S().tracklist.current_track;
                switch (e.keyval) {
                    case Gdk.Key.Tab:
                        Application.S().state = TracklistState.S();
                        return;
                    case Gdk.Key.F2:
                        Application.S().state = ConfigState.S();
                        return;
                    case Gdk.Key.r:
                        if ((bool)(e.state & Gdk.ModifierType.CONTROL_MASK) && t != null) {
                            t.reload();
                        } else {
                            var wv = Application.S().get_web_view(t);
                            if (wv != null)
                                wv.key_press_event(e);
                        }
                        break;
                    case Gdk.Key.f:
                        if ((bool)(e.state & Gdk.ModifierType.CONTROL_MASK) && t != null) {
                            t.search();
                        } else {
                            var wv = Application.S().get_web_view(t);
                            if (wv != null)
                                wv.key_press_event(e);
                        }
                        break;
                    case Gdk.Key.y:
                        if ((bool)(e.state & Gdk.ModifierType.CONTROL_MASK) && t != null) {
                            var wv = Application.S().get_web_view(t);
                            var c = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
                            c.set_text(wv.get_uri(),-1);
                        } else {
                            var wv = Application.S().get_web_view(t);
                            if (wv != null)
                                wv.key_press_event(e);
                        }
                        break;
                    default:
                        var wv = Application.S().get_web_view(t);
                        if (wv != null)
                            wv.key_press_event(e);
                        break;
                }
            }
            else if (Application.S().state is TracklistState) {
                switch (e.keyval) {
                    case Gdk.Key.Tab:
                        Application.S().state = NormalState.S();
                        return;
                    case Gdk.Key.F2:
                        Application.S().state = ConfigState.S();
                        return;
                    case Gdk.Key.Up:
                        Focus.S().move(Focus.Direction.UP);
                        return;
                    case Gdk.Key.Down:
                        Focus.S().move(Focus.Direction.DOWN);
                        return;
                    case Gdk.Key.Left:
                        Focus.S().move(Focus.Direction.LEFT);
                        return;
                    case Gdk.Key.Right:
                        Focus.S().move(Focus.Direction.RIGHT);
                        return;
                    case Gdk.Key.Return:
                        Focus.S().activate();
                        return;
                }
            }
            else if (Application.S().state is SessiondialogState) {
                switch (e.keyval) {
                    case Gdk.Key.Left:
                        Application.S().sessiondialog.select_restore();
                        return;
                    case Gdk.Key.Right:
                        Application.S().sessiondialog.select_newsession();
                        return;
                    case Gdk.Key.Return:
                        Application.S().sessiondialog.execute_selected();
                        return;
                }
            }
            else if (Application.S().state is ConfigState) {
                switch (e.keyval) {
                    case Gdk.Key.Escape:
                        Application.S().state = NormalState.S();
                        break;
                    case Gdk.Key.Tab:
                        Application.S().state = TracklistState.S();
                        break;
                        
                }
            }
        }
    }
}
