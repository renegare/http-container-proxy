Feature: Generate Proxy Config
In order to update nginx proxy config with the latest
avaialble backend servers I need to be able to generate
the config correctly

Scenario: Generate Empty Config
    Given the etcd namespace '/namespace-10.0.0.1-web' does not exist
    When I run the command:
    """
    docker run \
        -e ETCD_HOST=http://{{etcd.host}}:{{etcd.p4001}} \
        -e ETCD_NAMESPACE=/namespace-10.0.0.1-web \
        {{image}} generate-proxy-config
    """

    Then I expect the output of the command to be:
    """
    """

Scenario: Generate Config
    Given the etcd namespace '/namespace-10.0.0.1-web' does not exist
    And I set the following etcd data:
    | key | value |
    | /namespace-10.0.0.1-web/application_name_2/v3rs10n/proc4 | {"domain":"www.example2.com","host":"172.0.0.4","ports":{"80":"49994"}} |
    | /namespace-10.0.0.1-web/application_name_2/v3rs10n/proc3 | {"domain":"www.example2.com","host":"172.0.0.3","ports":{"80":"49993"}} |
    | /namespace-10.0.0.1-web/application_name_1/v3rs10n/proc1 | {"domain":"www.example.com","host":"172.0.0.1","ports":{"80":"49991"}} |
    | /namespace-10.0.0.1-web/application_name_1/v3rs10n/proc2 | {"domain":"www.example.com","host":"172.0.0.2","ports":{"80":"49992"}} |
    | /namespace-10.0.0.2-web/application_name_1/v3rs10n/proc1 | {"domain":"www.example.com","host":"172.0.0.1","ports":{"80":"49991"}} |
    | /namespace-10.0.0.2-web/application_name_1/v3rs10n/proc2 | {"domain":"www.example.com","host":"172.0.0.2","ports":{"80":"49992"}} |
    When I run the command:
    """
    docker run \
        -e ETCD_HOST=http://{{etcd.host}}:{{etcd.p4001}} \
        -e ETCD_NAMESPACE=/namespace-10.0.0.1-web \
        {{image}} generate-proxy-config
    """

    Then I expect the output of the command to be:
    """
    upstream www_example_com {
        server 172.0.0.1:49991;
        server 172.0.0.2:49992;
    }

    server {
        listen 80;
        server_name www.example.com;

        location / {
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://www_example_com;
        }
    }

    upstream www_example2_com {
        server 172.0.0.3:49993;
        server 172.0.0.4:49994;
    }

    server {
        listen 80;
        server_name www.example2.com;

        location / {
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://www_example2_com;
        }
    }
    """
