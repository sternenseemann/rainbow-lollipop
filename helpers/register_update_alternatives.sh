for alt in x-www-browser gnome-www-browser; do
    update-alternatives --install \
        /usr/bin/$alt $alt /usr/local/bin/rainbow-lollipop 0 \
            --slave /usr/share/man/man1/$alt.1.gz $alt.1.gz /usr/share/man/man1/rainbow-lollipop.1.gz
done

