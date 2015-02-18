using Sqlite;

namespace alaia {
    private const string DBINIT = """
        CREATE TABLE History (
            HIS_URL VARCHAR,
            HIS_CALLS INT,
        );
    """;

    class Database {
        private static Database instance;
        private Sqlite.Database db;
        private bool initialized=false;

        private Database () {
            string dbpath = Application.get_data_filename("alaia.sqlite3");
            int err = Sqlite.Database.open_v2(dbpath, out this.db, Sqlite.OPEN_READWRITE);
            if (err != Sqlite.OK) {
                err = Sqlite.Database.open_v2(dbpath, out this.db, Sqlite.OPEN_CREATE);
                if (err != Sqlite.OK) {
                    warning("Could not create database\n");
                }
                err = this.db.exec(DBINIT);
                if (err != Sqlite.OK) {
                    warning("Could not create tables\n");
                }
                
                
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
