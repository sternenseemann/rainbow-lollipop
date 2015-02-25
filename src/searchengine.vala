namespace alaia {
    /**
     * Represents the DuckDuckGo Searchengine as a hintprovider
     * See duckduckgo at https://duckduckgo.com
     */
    class DuckDuckGo : IHintProvider {
        private static DuckDuckGo instance;
        
        private DuckDuckGo(){}

        /**
         * Obtain the singleton instance of DuckDuckGo
         */
        public static DuckDuckGo S() {
            if (DuckDuckGo.instance == null)
                DuckDuckGo.instance = new DuckDuckGo();
            return DuckDuckGo.instance;
        }

        /**
         * Returns a hint that lets the user search the given fragment
         * via https://duckduckgo.com
         */
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
