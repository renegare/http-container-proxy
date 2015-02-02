<?php

namespace App\Command;

use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Command\Command;
use App\EtcdClient;
use GuzzleHttp\Exception\ClientException;

class GenerateProxyCommand extends Command {
    protected function configure() {
        $this
            ->setName('generate:proxy:config')
            ->setDescription('Generate a config based on all the registered services in etcd')

            ->addArgument('etcd_host',   InputArgument::REQUIRED, 'comma seperated list of hosts')
            ->addArgument('etcd_namespace',   InputArgument::REQUIRED, 'index to truncate')
            // ->addArgument('meta',   InputArgument::OPTIONAL, 'path to meta file, used when recreating index', null)
        ;
    }

    // sorting algorithm shit?!
    protected function groupServices($services) {
        $group = [];
        array_walk($services, function($service) use (&$group) {
            if(!isset($group[$service['domain']])) {
                $group[$service['domain']] = [
                    'name'      => str_replace('.', '_', $service['domain']),
                    'domain'    => $service['domain'],
                    'backend'   => []
                ];
            }
            $group[$service['domain']]['backend'][] = $service;
        });

        usort($group, function($groupA, $groupB) {
            return strnatcmp($groupA['domain'], $groupB['domain']);
        });

        array_walk($group, function(&$group) {
            usort($group['backend'], function($backendA, $backendB) {
                return strnatcmp($backendA['host'], $backendB['host']);
            });
        });

        return array_values($group);
    }

    protected function execute(InputInterface $input, OutputInterface $output) {
        $tmpl = $this->getTemplate();
        $namespace = $input->getArgument('etcd_namespace');

        try {
            $client = new EtcdClient($input->getArgument('etcd_host'));
            $directoryList = $client->getRecursive($namespace);
        } catch (ClientException $e) {
            $response = $e->hasResponse()? $e->getResponse() : null;
            if(!$response || $response->getStatusCode() !== 404) {
                throw $e;
            }
            $directoryList = [];
        }

        $pattern = sprintf('#^%s/([^/]+)/([^/]+)/([^/]+)$#', $namespace);
        array_walk($directoryList, function(&$value, $path) use ($pattern) {
            if(preg_match($pattern, $path, $matches)) {
                $value = json_decode($value, true);
                $value['name'] = $matches[1];
                $value['version'] = $matches[2];
                $value['sequence'] = $matches[3];
            } else{
                $value = '';
            }
        });

        $mustache = new \Mustache_Engine;
        $output->writeln($mustache->render($tmpl, ['group' => $this->groupServices($directoryList)]));
    }

    protected function getTemplate() {
        return <<<EOF
{{#group}}
upstream {{name}} {
    {{#backend}}
    server {{host}}:{{ports.80}};
    {{/backend}}
}

server {
    listen 80;
    server_name {{domain}};

    location / {
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://{{name}};
    }
}

{{/group}}
EOF;
    }
}
