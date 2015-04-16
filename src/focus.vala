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
    public abstract class Focusable : Clutter.Actor {
        public abstract Focusable? get_left_focusable();
        public abstract Focusable? get_right_focusable();
        public abstract Focusable? get_up_focusable();
        public abstract Focusable? get_down_focusable();
        public abstract void focus_activate();
    }

    class Focus : Clutter.Actor {
        public enum Direction {
            UP,
            DOWN,
            LEFT,
            RIGHT
        }
        public Focusable? focused_object {
            get {
                return this._focused_object;
            }
            set {
                if (this._focused_object != null)
                    this._focused_object.remove_child(this);
                this._focused_object = value;
                this._focused_object.add_child(this);
                this.set_size(this._focused_object.width, this._focused_object.height);
                this.c.set_size((int)this._focused_object.width, (int)this._focused_object.height);
            }
        }

        private Focusable? _focused_object;
        private Clutter.Canvas c;

        private static Focus instance;
        public static Focus S() {
            if (Focus.instance == null) {
                Focus.instance = new Focus();
            }
            return Focus.instance;
        }

        private Focus() {
            this.c = new Clutter.Canvas();
            this.x = this.y = 0;
            this.content = c;
            this.c.draw.connect(this.do_draw);
        }

        public bool do_draw(Cairo.Context cr, int w, int h) {
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_source_rgba(1,1,1,1);
            cr.set_operator(Cairo.Operator.OVER);
            // Upper left corner
            cr.move_to(0, h/10);
            cr.line_to(0, 0);
            cr.line_to(w/10, 0);
            cr.stroke();
            // Upper right corner
            cr.move_to(w, h/10);
            cr.line_to(w, 0);
            cr.line_to(w-w/10, 0);
            cr.stroke();
            // Lower left corner
            cr.move_to(0, h-h/10);
            cr.line_to(0, h);
            cr.line_to(w/10, h);
            cr.stroke();
            // Lower right corner
            cr.move_to(w, h-h/10);
            cr.line_to(w, h);
            cr.line_to(w-w/10, h);
            cr.stroke();
            return true;
        }

        public void move(Direction d) {
            if (this.focused_object != null) {
                Focusable? to_focus = null;
                switch (d) {
                    case Direction.UP:
                        to_focus = this.focused_object.get_up_focusable();
                        break;
                    case Direction.DOWN:
                        to_focus = this.focused_object.get_down_focusable();
                        break;
                    case Direction.LEFT:
                        to_focus = this.focused_object.get_left_focusable();
                        break;
                    case Direction.RIGHT:
                        to_focus = this.focused_object.get_right_focusable();
                        break;
                }
                this.focused_object = to_focus;
            }
        }
    }
}
