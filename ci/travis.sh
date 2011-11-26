#!/bin/sh

set -e

solr_responding() {
  port=$1
  curl -o /dev/null "http://localhost:$port/solr" > /dev/null 2>&1
}

wait_until_solr_responds() {
  port=$1
  while ! solr_responding $1; do
    /bin/echo -n "."
    sleep 1
  done
}

case $GEM in
  "sunspot")
    
    cd sunspot
    /bin/echo -n "Starting Solr on port 8983 for Sunspot specs..."
    bundle install --quiet --path vendor/bundle
    if [ -f sunspot-solr.pid ]; then bundle exec sunspot-solr stop || true; fi

    export SOLR_URL=http://localhost:8983/solr
    bundle exec sunspot-solr start -p 8983 -d /tmp/solr
    wait_until_solr_responds 8983
    /bin/echo "done."
    
    # Invoke the sunspot specs
    bundle exec rake spec
    
    /bin/echo -n "Stopping Solr... "
    bundle exec sunspot-solr stop
    /bin/echo "done."
    ;;
    
  "sunspot_rails")
  
    cd sunspot
    /bin/echo -n "Starting Solr on port 8983 for Sunspot specs..."
    bundle install --quiet --path vendor/bundle -d /tmp/solr
    if [ -f sunspot-solr.pid ]; then bundle exec sunspot-solr stop || true; fi

    export SOLR_URL=http://localhost:8983/solr
    bundle exec sunspot-solr start -p 8983
    wait_until_solr_responds 8983
    /bin/echo "done."
    
    # Install gems for test Rails application
    cd ../sunspot_rails
    rake spec RAILS=$RAILS
    
    # Cleanup Solr
    /bin/echo -n "Stopping Solr... "
    cd ../sunspot
    bundle exec sunspot-solr stop
    /bin/echo "done."
    ;;
    
  *)
esac
