namespace alaia {
    class DuckDuckGo : IHintProvider {
        private static DuckDuckGo instance;
        
        private DuckDuckGo(){}

        public static DuckDuckGo S() {
            if (DuckDuckGo.instance == null)
                DuckDuckGo.instance = new DuckDuckGo();
            return DuckDuckGo.instance;
        }

        public Gee.ArrayList<AutoCompletionHint> get_hints(string fragment){
            var ret = new Gee.ArrayList<AutoCompletionHint>();
            var hint = new AutoCompletionHint(
                        "Search %s".printf(fragment),
                        "Search for %s with DuckDuckGo".printf(fragment)
            );
            var icon_path = Application.get_data_filename("ddg.png");
            var surface = new Cairo.ImageSurface.from_png(icon_path);
            hint.set_icon(surface);
            hint.execute.connect((tl) => {
                tl.add_track_with_url("https://duckduckgo.com/?q=%s".printf(fragment));
            });
            ret.add(hint);
            return ret;
        }
    }
}
