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

namespace alaia {
    /**
     * A History class that logs calls to URLs into a SQL Database
     * It serves as HintProvider and can deliver hints to URLS that have
     * Already been surfed to.
     * TODO: There should be a third column which is called HIS_TITLE
     *       An URL should also qualify for being a hint when it's associated HTML-title
     *       contains the searched string fragment.
     *       Fuzzy searching would also be awesome.
     */
    class History : IHintProvider {
        /**
         * Statement that creates the tables necessary for this class
         */
        public const string DBINIT = """
            CREATE TABLE IF NOT EXISTS History (
                HIS_URL VARCHAR PRIMARY KEY,
                HIS_CALLS INT NOT NULL
            );
        """;

        /**
         * Statement to generate hints
         */
        private static const string LOG_HINTQRY = """
            SELECT HIS_URL FROM HISTORY
            WHERE HIS_URL LIKE $URL
            ORDER BY HIS_CALLS DESC
            LIMIT $LIM;
        """;

        /**
         * Statement to Check if an URL has already been logged
         */
        private static const string LOG_QRY = """
            SELECT COUNT(HIS_CALLS) AS CNT FROM History WHERE HIS_URL = $URL;
        """;

        /**
         * Statement to Insert a new URL into the log
         */
        private static const string LOG_INSERT = """
            INSERT INTO History (HIS_URL, HIS_CALLS) VALUES ($URL, 1);
        """;

        /**
         * Statement to increment a logged URLs call counter
         */
        private static const string LOG_UPDATE = """
            UPDATE History SET
                HIS_CALLS = 1+(SELECT HIS_CALLS FROM History WHERE HIS_URL = $URL)
            WHERE HIS_URL = $URL;
        """;

        private static History instance;

        private History() {
        }

        /**
         * Returns the singleton instance of History
         */
        public static History S() {
            if (History.instance == null) {
                History.instance = new History();
            }
            return History.instance;
        }

        /**
         * Logs a callto an URL into the History Database
         */
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

        /**
         * Generates a list of URL-Related Hints. An URL qualifies for being
         * a hint by containing the searched url_fragment. If more than
         * one is found, the URLs are ordered descendingly by the number of their
         * calls.
         */
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
                string url = stmnt.column_text(0);
                hint = new AutoCompletionHint(
                                url,
                                "Surf directly to \n%s".printf(url)
                );
                var favdb = WebKit.WebContext.get_default().get_favicon_database();
                favdb.get_favicon.begin(url,null, (obj, res) => {
                    Cairo.Surface fav;
                    try {
                        fav = favdb.get_favicon.end(res);
                    } catch (Error e) { return; }
                    hint.set_icon(fav);
                });
                hint.execute.connect((tl) => {
                    tl.add_track_with_url(url);
                });
                ret.add(hint);
            }
            return ret;
        }
    }
}
