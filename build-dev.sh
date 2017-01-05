#!/bin/bash
docker exec -it laradock_workspace_1 php artisan down

# get the updates for ref << login
docker exec -it laradock_workspace_1 git fetch

# diff with the updates
ifStatementConditional=$(docker exec -it laradock_workspace_1 git diff --name-only HEAD origin/develop | grep -c 'migrations')
echo $ifStatementConditional

# if migrations then migrate after pull << login
if [ $ifStatementConditional -gt 0 ] ; then 
    echo 'Migrate --';
    docker exec -it laradock_workspace_1 git pull
    docker exec -it laradock_workspace_1 php artisan migrate
else
    echo 'Pull --';
    docker exec -it laradock_workspace_1 git pull
fi

# then check composer vendor install
# cache clean
# compile
# restart workers
docker exec -it laradock_workspace_1 composer.phar install

# check ownership ok -- remmber chown inside container is workspace not php-fpm user ids
docker exec -it laradock_workspace_1 chown -R www-data:www-data /var/www/laravel/

# showing perm issues when currently running << Maybe clear cache instead?
docker exec -it laradock_workspace_1 chmod -R a+w /var/www/laravel/storage/framework/views/
docker exec -it laradock_workspace_1 chmod -R a+w /var/www/laravel/storage/framework/cache/
docker exec -it laradock_workspace_1 chmod -R a+w /var/www/laravel/resources/lang/en/

# bring site back
docker exec -it laradock_workspace_1 php artisan up

# log change to rollbar
ACCESS_TOKEN=long-long-token
ENVIRONMENT=local
LOCAL_USERNAME=`whoami`
REVISION=`git log -n 1 --pretty=format:"%H"`

curl https://api.rollbar.com/api/1/deploy/ \
  -F access_token=$ACCESS_TOKEN \
  -F environment=$ENVIRONMENT \
  -F revision=$REVISION \
  -F local_username=$LOCAL_USERNAME

echo '__end';
