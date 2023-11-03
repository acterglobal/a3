cd app
flutter run integration_test/main_test.dart  \
    --host-vmservice-port 9753 \
    --disable-service-auth-codes \
    --dart-define CONVENIENT_TEST_APP_CODE_DIR=lib \
    --dart-define DEFAULT_HOMESERVER_URL=http://localhost:8118/ \
    --dart-define DEFAULT_HOMESERVER_NAME=localhost \
    --dart-define CONVENIENT_TEST_MANAGER_HOST=10.0.2.2 \
    --dart-define DEFAULT_HOMESERVER_URL=http://10.0.2.2:8118/
    --dart-define CI=true \
    &
subscript_pid=$!

# actual manager runner
dart run convenient_test_manager_dart --enable-report-saver
exit_status=$?
kill "$subscript_pid"
exit exit_status