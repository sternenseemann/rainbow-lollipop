namespace alaia {
    class History : IHintProvider {
        public const string DBINIT = """
            CREATE TABLE IF NOT EXISTS History (
                HIS_URL VARCHAR PRIMARY KEY,
                HIS_CALLS INT NOT NULL
            );
        """;
        private static const string LOG_HINTQRY = """
            SELECT HIS_URL FROM HISTORY
            WHERE HIS_URL LIKE $URL
            ORDER BY HIS_CALLS DESC
            LIMIT $LIM;
        """;
        private static const string LOG_QRY = """
            SELECT COUNT(HIS_CALLS) AS CNT FROM History WHERE HIS_URL = $URL;
        """;
        private static const string LOG_INSERT = """
            INSERT INTO History (HIS_URL, HIS_CALLS) VALUES ($URL, 1);
        """;
        private static const string LOG_UPDATE = """
            UPDATE History SET
                HIS_CALLS = 1+(SELECT HIS_CALLS FROM History WHERE HIS_URL = $URL)
            WHERE HIS_URL = $URL;
        """;

        private static History instance;

        private History() {
        }

        public static History S() {
            if (History.instance == null) {
                History.instance = new History();
            }
            return History.instance;
        }

        public static void log_call(string url) {
            // Check if entry already exists in db
            unowned Sqlite.Database  db = Database.S().get_db();
            Sqlite.Statement stmnt;
            int err = db.prepare_v2(LOG_QRY,LOG_QRY.length, out stmnt);
            if (err != Sqlite.OK) {
                warning("Could not prepare LOG_QRY: %s", db.errmsg());
                return;
            }
            int url_param_pos = stmnt.bind_parameter_index("$URL");
            assert (url_param_pos > 0);
            stmnt.bind_text(url_param_pos, url);
            bool entry_found = false;
            while (stmnt.step() == Sqlite.ROW) {
                entry_found = stmnt.column_int(0) > 0;
            }
            stmnt.reset();
            if (entry_found) {
                // If yes, count up
                err = db.prepare_v2(LOG_UPDATE, LOG_UPDATE.length, out stmnt);
                if (err != Sqlite.OK) {
                    warning("Could not prepare LOG_UPDATE: %s", db.errmsg());
                    return;
                }
            } else {
                // If no, create
                err = db.prepare_v2(LOG_INSERT, LOG_INSERT.length, out stmnt);
                if (err != Sqlite.OK) {
                    warning("Could not prepare LOG_INSERT: %s", db.errmsg());
                    return;
                }
            }
            url_param_pos = stmnt.bind_parameter_index("$URL");
            assert(url_param_pos > 0);
            stmnt.bind_text(url_param_pos, url);
            stmnt.step();
        }

        public Gee.ArrayList<AutoCompletionHint> get_hints(string url_fragment) {
            var ret = new Gee.ArrayList<AutoCompletionHint>();
            unowned Sqlite.Database db = Database.S().get_db();
            Sqlite.Statement stmnt;
            int err = db.prepare_v2(LOG_HINTQRY, LOG_HINTQRY.length, out stmnt);
            if (err != Sqlite.OK) {
                warning("Could not prepare LOG_HINTQRY: %s", db.errmsg());
                return ret;
            }
            int url_param_pos = stmnt.bind_parameter_index("$URL");
            int lim_param_pos = stmnt.bind_parameter_index("$LIM");
            assert (url_param_pos > 0);
            assert (lim_param_pos > 0);
            stmnt.bind_text(url_param_pos, "%%%s%%".printf(url_fragment));
            stmnt.bind_int(lim_param_pos, Config.c.urlhint_limit);
            AutoCompletionHint hint;
            while(stmnt.step() == Sqlite.ROW) {
                hint = new AutoCompletionHint(stmnt.column_text(0), stmnt.column_text(0));
                ret.add(hint);
            }
            return ret;
        }
    }
}
