# global install: nodejs, gulp, forever, coffee-script, bower
# copy config
sudo service stop site-journal
npm install --production
bower install --config.interactive=false
gulp build
NODE_ENV=production forever start -c coffee journal-server.coffee
sudo service start site-journal