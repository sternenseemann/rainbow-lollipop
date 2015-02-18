namespace alaia {
    class History : IHintProvider {
        private static History instance;

        public History() {
        }

        public static History S() {
            if (History.instance = null) {
                History.instance = new History();
            }
            return History.instance;
        }

        public static void log_call(string url) {
            // Check if entry already exists in db
            // If yes, count up
            // If no, create
        }

        public Gee.ArrayList<AutoCompletionHint> get_hints(string url) {
            var ret = new Gee.ArrayList<AutoCompletionHint>();
            return ret;
        }
    }

    class URLHint : AutoCompletionHint {
        public new void render() {
        }
    }
}
