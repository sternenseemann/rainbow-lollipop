using Sqlite;

namespace alaia {
    /**
     * Wrapper around Sqlite3 as Singleton.
     * Is used to cache Data e.g. The called urls and how often they have been called
     */
    class Database {
        private static Database instance;
        private Sqlite.Database db;
        private bool initialized=false;

        /**
         * Initializes a sqlite3 datase or opens it, depending on
         * whether it exists or not.
         */
        private Database () {
            string dbpath = Application.get_cache_filename("alaia.sqlite3");
            int err = Sqlite.Database.open(dbpath, out this.db);
            if (err != Sqlite.OK) {
                warning("Could not create database %s\n", this.db.errmsg());
                return;
            }
            err = this.db.exec(History.DBINIT);
            if (err != Sqlite.OK) {
                warning("Could not create tables %s\n", this.db.errmsg());
                return;
            }
            this.initialized = true;
        }

        /**
         * Returns the singleton instance of Database
         */
        public static Database S() {
            if (Database.instance == null) {
                Database.instance = new Database();
            }
            return Database.instance;
        }

        /**
         * Returns true if the database has been initialized correctly.
         */
        public bool check_initialized() {
            if (!this.initialized) 
                warning("Database is not initialized. Can not commit statement\n");
            return this.initialized;
        } 

        /**
         * Returns a reference to the wrapped Sqlite.Database-object
         */
        public unowned Sqlite.Database get_db() {
            return this.db;
        }
    }
}
