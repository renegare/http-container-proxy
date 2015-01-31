Feature: Healthcheck
As sysadmin I need a public endpoint in order
to determine if the application is reachable and running

Scenario: 200 response from healthcheck
    Given I am on the healthcheck page
    Then the response status code should be 200
    And I should see "All Good!"
