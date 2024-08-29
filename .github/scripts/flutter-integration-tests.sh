cd app
flutter run integration_test/main_test.dart  \
    --host-vmservice-port 9753 \
    --hot \
    --disable-service-auth-codes \
    --dart-define CONVENIENT_TEST_APP_CODE_DIR=lib \
    --dart-define CONVENIENT_TEST_MANAGER_HOST=10.0.2.2 \
    --dart-define RAGESHAKE_URL=http://10.0.2.2:9110/api/submit \
    --dart-define MAILHOG_URL=http://10.0.2.2:8025 \
    --dart-define RAGESHAKE_LISTING_URL=http://10.0.2.2:9110/api/listing \
    &
subscript_pid=$!

# in our experience it takes about four mins on CI to startup the app

BAR='#######################'   # this is full bar, e.g. 20 chars

for i in {1..24}; do
    echo -ne "\r$i/24 ${BAR:0:$i}" # print $i chars of $BAR from 0 position
    sleep 10                 # wait 10s between "frames"
done
echo "\n"

echo "Starting manager"

# actual manager runner
dart run convenient_test_manager_dart --enable-report-saver "$@"
exit_status=$?
kill "$subscript_pid"
exit $exit_status
