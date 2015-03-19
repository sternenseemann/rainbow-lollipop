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
     * This is a bullet that resembles a stopsign and renders
     * Its parent stored errorcode as text.
     */
    class ErrorBullet : Clutter.Actor {
        private Clutter.Canvas c;
        private ErrorNode parent;

        /**
         * Initializes and returns a new ErrorBullet
         */
        public ErrorBullet (ErrorNode parent) {
            this.parent = parent;
            this.c = new Clutter.Canvas();
            this.x = this.y = 0;
            this.content = c;
            this.set_size(rnd(parent.width), rnd(parent.height));
            this.c.set_size(rnd(parent.width), rnd(parent.height));
            this.c.draw.connect(do_draw);
            this.c.invalidate();
        }

        /**
         * Realizes the errornode on screen
         */
        public bool do_draw(Cairo.Context cr, int w, int h) {
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_source_rgba(col_h2f(this.parent.color.red)*2,
                              col_h2f(this.parent.color.green)*2,
                              col_h2f(this.parent.color.blue)*2,
                              1);
            cr.set_operator(Cairo.Operator.OVER);
            cr.set_line_width(Config.c.bullet_stroke);
            var nh = Config.c.node_height;
            var bs = Config.c.bullet_stroke;
            cr.move_to(nh / 3, bs);
            cr.line_to(nh / 3 * 2, bs);
            cr.line_to(nh-bs, nh / 3);
            cr.line_to(nh-bs, nh / 3 * 2);
            cr.line_to(nh / 3 * 2, nh-bs);
            cr.line_to(nh / 3, nh-bs);
            cr.line_to(bs, nh / 2 * 3);
            cr.line_to(bs, nh / 3);
            cr.line_to(nh / 3, bs);
            cr.stroke();
            return true;
        }
    }

    /**
     * This class is a Node that will be used when HTTP-calls return
     * HTTP-errors. It resembles a traffic-stopsign and contains the
     * HTTP-errorcode as text.
     */
    class ErrorNode : Node {
        private Error e;
        private ErrorBullet bullet;
        private Clutter.Text text;

        /**
         * Creates and returns a new ErrorNode
         */
        public ErrorNode(HistoryTrack track, Error error, Node? par) {
            base(track, par);
            this.e = error;
            this.bullet = new ErrorBullet(this);
            this.add_child(this.bullet);
            this.text = new Clutter.Text.with_text("Monospace Bold 9", "404");
            this.text.color = this.color.darken().darken().darken();
            this.text.x = Config.c.node_height/2-this.text.width/2;
            this.text.y = Config.c.node_height/2-this.text.height/2;
            this.add_child(this.text);

            this.opacity = 0x7F;
            this.background_color = this.color;
        }
    }
}
