#!/bin/bash
# in our experience it takes about four mins on CI to startup the app
PROGRESS_BAR_WIDTH=50  # progress bar length in characters

draw_progress_bar() {
  # Arguments: current value, max value, unit of measurement (optional)
  local __value=$1
  local __max=$2
  local __unit=${3:-""}  # if unit is not supplied, do not display it

  # Calculate percentage
  if (( $__max < 1 )); then __max=1; fi  # anti zero division protection
  local __percentage=$(( 100 - ($__max*100 - $__value*100) / $__max ))

  # Rescale the bar according to the progress bar width
  local __num_bar=$(( $__percentage * $PROGRESS_BAR_WIDTH / 100 ))

  # Draw progress bar
  printf "["
  for b in $(seq 1 $__num_bar); do printf "#"; done
  for s in $(seq 1 $(( $PROGRESS_BAR_WIDTH - $__num_bar ))); do printf " "; done
  printf "] $__percentage%% ($__value / $__max $__unit)\r"
}

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

for i in {1..240}; do
    draw_progress_bar $i 240 'seconds'
    sleep 1
done
echo "\n"

echo "Starting manager"

# actual manager runner
dart run convenient_test_manager_dart --enable-report-saver "$@"
exit_status=$?
kill "$subscript_pid"
exit $exit_status
