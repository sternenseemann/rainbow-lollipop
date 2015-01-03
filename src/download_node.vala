namespace alaia {
    class DownloadNode : Node {
        private Clutter.Canvas c;
        private WebKit.Download dl;

        public DownloadNode(HistoryTrack track, WebKit.Download download, Node? par) {
            base(track,par);
            
            this.background_color = this.color;
            this.dl = download;
        }
        
    }
}
