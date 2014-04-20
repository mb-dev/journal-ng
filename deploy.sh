# global install: nodejs, gulp, forever, coffee-script, bower
# copy config
git pull
npm install --production
bower install
gulp build
forever stop journal-server.coffee
NODE_ENV=production forever start -c coffee journal-server.coffee
