<?php

namespace App;

use GuzzleHttp\Client;
use GuzzleHttp\Exception\ClientException;

class EtcdClient {
    protected $host;

    public function __construct($host) {
        $this->host = $host;
    }

    public function exists($namespace){
        $client = $this->getClient();
        $path = preg_replace('#^/#', '', $namespace);
        
        try {
            $client->head('/v2/keys/' . $path, [
                'query' => ['recursive' => 'true']
            ]);

            return true;
        } catch (ClientException $e) {
            $response = $e->getResponse();
            if($response->getStatusCode() === 404) {
                return false;
            }
            throw $e;
        }
    }

    public function remove($namespace){
        $client = $this->getClient();
        $path = preg_replace('#^/#', '', $namespace);
        
        return $client->delete('/v2/keys/' . $path, [
            'query' => ['recursive' => 'true']
        ]);
    }

    public function set($key, $value) {
        $path = preg_replace('#^/#', '', $key);
        $client = $this->getClient();
        return $client->put('/v2/keys/' . $path, [
            'body' => ['value' => $value]
        ]);
    }

    protected function getClient() {
        return new Client(['base_url' => $this->host]);
    }

    public function getRecursive($namespace) {
        $path = preg_replace('#^/#', '', $namespace);
        $client = $this->getClient();
        $list = $client->get('/v2/keys/' . $path, [
                'query' => ['recursive' => 'true']
            ])->json();
        return $this->normalizeList(isset($list['node']['nodes'])? $list['node']['nodes'] : []);
    }

    public function normalizeList(array $list) {
        $normalized = [];
        foreach($list as $item) {
            if(isset($item['value'])) {
                $normalized[$item['key']] = $item['value'];
            } else if(isset($item['dir']) && $item['dir']) {
                $normalized = array_merge($normalized, $this->normalizeList($item['nodes']));
            }
        }
        return $normalized;
    }
}
