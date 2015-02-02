@slow
Feature: Reload Proxy
Whenever a change is detected within the namespace of etcd,
The nginx proxy should be reloaded with new configuration (akin blue, green deployment)

Background: Start the proxy and backend services
    Given I run the following commands:
    """
    docker stop {{image}}_tmp 2>/dev/null | xargs docker kill | xargs docker rm || true

    docker run -dP \
        --name {{image}}_tmp \
        --link {{blue.name}}:blue.backend.com \
        --link {{green.name}}:green.backend.com \
        -e ETCD_HOST=http://{{etcd.host}}:{{etcd.p4001}} \
        -e ETCD_NAMESPACE=/namespace-10.0.0.1-web \
        {{image}} start
    """
    And I wait for 3 second

Scenario: Blue Deployment
    Given the etcd namespace '/namespace-10.0.0.1-web' does not exist
    When I run the command:
    """
    docker run \
        --link {{app.name}}_tmp:www.example.com \
        renegare/php curl -w 'Status Code: %{http_code}' -s --output /dev/null http://www.example.com
    """

    Then I expect the output of the command to be:
    """
    Status Code: 404
    """

    When I set the following etcd data:
    | key | value |
    | /namespace-10.0.0.1-web/application_name_2/v3rs10n/proc4 | {"domain":"www.example.com","host":"blue.backend.com","ports":{"80":"80"}} |

    And I wait for 3 second

    And I run the command:
    """
    docker run \
        --link {{app.name}}_tmp:www.example.com \
        renegare/php curl -w 'Status Code: %{http_code}' -s http://www.example.com
    """

    Then I expect the output of the command to be:
    """
    Blue Server
    Status Code: 200
    """

    When the etcd namespace '/namespace-10.0.0.1-web' does not exist
    And I wait for 3 second
    And I set the following etcd data:
    | key | value |
    | /namespace-10.0.0.1-web/application_name_2/v3rs10n/proc4 | {"domain":"www.example.com","host":"green.backend.com","ports":{"80":"80"}} |
    And I wait for 3 second
    And I run the command:
    """
    docker run \
        --link {{app.name}}_tmp:www.example.com \
        renegare/php curl -w 'Status Code: %{http_code}' -s http://www.example.com
    """

    Then I expect the output of the command to be:
    """
    Green Server
    Status Code: 200
    """

    When the etcd namespace '/namespace-10.0.0.1-web' does not exist
    And I wait for 3 second
    And I run the command:
    """
    docker run \
        --link {{app.name}}_tmp:www.example.com \
        renegare/php curl -w 'Status Code: %{http_code}' -s --output /dev/null http://www.example.com
    """

    Then I expect the output of the command to be:
    """
    Status Code: 404
    """
