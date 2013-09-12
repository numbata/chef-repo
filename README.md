Сетап окружения

    git submodule update --init
    bundle install
    librarian-chef install
    bundle exec knife solo bootstrap --color USER@HOST -N NODENAME
