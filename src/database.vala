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
