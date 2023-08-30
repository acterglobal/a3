Feature: Login Smoketest
  Trying to login and ensure it works

  Scenario: After login, ensure username
    Given kyra has logged in
    Given App has settled
