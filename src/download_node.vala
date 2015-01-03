namespace alaia {
    class ProgressBullet : Clutter.Actor {
        private Clutter.Canvas c;
        private DownloadNode parent;
        private double fraction = 50.0;
        public ProgressBullet(DownloadNode parent) {
            this.parent = parent;
            this.c = new Clutter.Canvas();
            this.x = 0;
            this.y = 0;
            this.content = c;
            this.set_size(rnd(parent.width), rnd(parent.height));
            this.c.set_size(rnd(parent.width), rnd(parent.height));
            this.c.draw.connect(do_draw);
            this.c.invalidate();
        }

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
            cr.rectangle(Config.c.bullet_stroke,
                         Config.c.bullet_stroke,
                         Config.c.node_height-2*Config.c.bullet_stroke,
                         Config.c.node_height-2*Config.c.bullet_stroke);
            cr.stroke();
            cr.set_source_rgba(col_h2f(this.parent.color.red),
                              col_h2f(this.parent.color.green),
                              col_h2f(this.parent.color.blue),
                              1.0);
            cr.rectangle(5,5,this.fraction*(Config.c.node_height-10),Config.c.node_height-10);
            cr.fill();
            return true;
        }

        public void set_fraction(double fraction) {
            this.fraction = fraction;
            this.c.invalidate();
        }
    }

    class DownloadNode : Node {
        private WebKit.Download dl;
        private bool finished=false;
        private ProgressBullet progress;
        private Clutter.Text text;

        public DownloadNode(HistoryTrack track, WebKit.Download download, Node? par) {
            base(track,par);
            this.dl = download;
            this.progress = new ProgressBullet(this);
            this.add_child(this.progress);
            this.text = new Clutter.Text.with_text("Monospace Bold 9", "0 %%");
            this.text.color = this.color.darken().darken().darken();
            this.text.x = Config.c.node_height/2-this.text.width/2;
            this.text.y = Config.c.node_height/2-this.text.height/2;
            this.add_child(this.text);
            
            this.opacity = 0x7F;
            this.background_color = this.color;
            this.dl.finished.connect(()=>{this.finished=true;});
            this.dl.failed.connect(()=>{this.finished=true;});
            this.clickaction.clicked.connect(do_clicked);
            GLib.Idle.add(this.update);
        }

        public bool update() {
            this.progress.set_fraction(this.dl.get_estimated_progress());
            double percent = this.dl.get_estimated_progress()*100;
            this.text.set_text("%d %%".printf((int)percent));
            this.text.x = Config.c.node_height/2-this.text.width/2;
            this.text.y = Config.c.node_height/2-this.text.height/2;
            if (!this.finished) {
                GLib.Idle.add(this.update);
            }
            return false;
        }

        public bool is_finished() {
            return this.finished;
        }

        private void open_path(File f) {
            try {
                var handler = f.query_default_handler(null);
                var arglist = new List<File>();
                arglist.append(f);
                handler.launch(arglist,null);
            } catch (GLib.Error e) {
                stderr.printf("Could not find a launcher for file: %s", f.get_path());
            }
        }

        public void open_folder() {
            var f = File.new_for_uri(this.dl.get_destination());
            this.open_path(f.get_parent());
        }

        public void open_download() {
            var f = File.new_for_uri(this.dl.get_destination());
            this.open_path(f);
        }

        private new void do_clicked(Clutter.Actor _) {
            base.do_clicked();
            stdout.printf("ohai\n");
        }
    }
}
