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

namespace RainbowLollipop {
    /**
     * The ContextMenu of Items displayed in the TrackList.
     * It displays different Actions according to what object has been clicked on:
     *
     * Track:
     *    - Close Track
     * Node:
     *    - Close Branch
     *    - New Track from Branch
     *    + SiteNode:
     *       - Copy URL
     *    + DownloadNode:
     *       - Open the downloaded File
     *       - Open the folder in which the downloaded file resides.
     */
    class ContextMenu : Gtk.Menu {
        private Gtk.ImageMenuItem new_track_from_node;
        private Gtk.ImageMenuItem delete_branch;
        private Gtk.ImageMenuItem copy_url;
        private Gtk.ImageMenuItem delete_track;
        private Gtk.ImageMenuItem open_folder;
        private Gtk.ImageMenuItem open_download;
        private Node? node;
        private Track? track;

        /**
         * Initializes the ContextMenu
         */
        public ContextMenu () {
            //Nodes
            this.new_track_from_node = new Gtk.ImageMenuItem.with_label(_("New Track from Branch"));
            this.new_track_from_node.set_image(
                new Gtk.Image.from_icon_name("go-jump", Gtk.IconSize.MENU)
            );
            this.new_track_from_node.activate.connect(do_new_track_from_node);
            this.add(this.new_track_from_node);
            this.delete_branch = new Gtk.ImageMenuItem.with_label(_("Close Branch"));
            this.delete_branch.set_image(
                new Gtk.Image.from_icon_name("edit-delete", Gtk.IconSize.MENU)
            );
            this.delete_branch.activate.connect(do_delete_branch);
            this.add(this.delete_branch);

            //Sitenodes
            this.copy_url = new Gtk.ImageMenuItem.with_label(_("Copy URL"));
            this.copy_url.set_image(
                new Gtk.Image.from_icon_name("edit-copy", Gtk.IconSize.MENU)
            );
            this.copy_url.activate.connect(do_copy_url);
            this.add(this.copy_url);


            //DownloadNodes
            this.open_folder = new Gtk.ImageMenuItem.with_label(_("Open folder"));
            this.open_folder.set_image(
                new Gtk.Image.from_icon_name("folder", Gtk.IconSize.MENU)
            );
            this.open_folder.activate.connect(do_open_folder);
            this.add(this.open_folder);
            this.open_download = new Gtk.ImageMenuItem.with_label(_("Open"));
            this.open_download.set_image(
                new Gtk.Image.from_icon_name("document-open", Gtk.IconSize.MENU)
            );
            this.open_download.activate.connect(do_open_download);
            this.add(this.open_download);

            //Track
            this.add(new Gtk.SeparatorMenuItem());
            this.delete_track = new Gtk.ImageMenuItem.with_label(_("Close Track"));
            this.delete_track.set_image(
                new Gtk.Image.from_icon_name("window-close", Gtk.IconSize.MENU)
            );
            this.delete_track.activate.connect(do_delete_track);
            this.add(this.delete_track);

            this.show_all();
        }

        /**
         * This method shows/hides actions of the menu according to whether
         * they are needed or not. The context is expressed by the combination
         * of either a track and a node, a track without a node or nothing.
         */
        public void set_context(Track? track, Node? node) {
            this.track = track;
            this.node = node;
            
            this.delete_track.visible = this.track != null;
            this.new_track_from_node.visible = this.node != null;
            this.copy_url.visible = this.node != null && this.node is SiteNode;
            this.open_folder.visible = this.node != null && this.node is DownloadNode;
            this.open_download.visible = this.node != null && this.node is DownloadNode &&
                                         (this.node as DownloadNode).is_finished();
            this.delete_branch.visible = this.node != null;
        }

        /**
         * Callbacks
         */
        public void do_new_track_from_node(Gtk.MenuItem m) {
            if (this.node != null)
                this.node.move_to_new_track();
        }
        public void do_delete_branch(Gtk.MenuItem m) {
            if (this.node  != null)
                this.node.delete_node();
        }
        public void do_copy_url(Gtk.MenuItem m) {
            if (this.node != null && this.node is SiteNode){
                var c = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
                c.set_text((this.node as SiteNode).url,-1);
            }
        }
        public void do_delete_track(Gtk.MenuItem m) {
            if (this.track != null)
                this.track.delete_track();
        }
        public void do_open_folder(Gtk.MenuItem m) {
            if (this.node is DownloadNode)
                (this.node as DownloadNode).open_folder();
        }
        public void do_open_download(Gtk.MenuItem m) {
            if (this.node is DownloadNode)
                (this.node as DownloadNode).open_download();
        }
    }
}
