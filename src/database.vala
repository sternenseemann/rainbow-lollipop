using Sqlite;

namespace alaia {

    class Database {
        private static Database instance;
        private Sqlite.Database db;
        private bool initialized=false;

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

        public static Database S() {
            if (Database.instance == null) {
                Database.instance = new Database();
            }
            return Database.instance;
        }

        public bool check_initialized() {
            if (!this.initialized) 
                warning("Database is not initialized. Can not commit statement\n");
            return this.initialized;
        } 

        public unowned Sqlite.Database get_db() {
            return this.db;
        }
    }
}
