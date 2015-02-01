<?php

namespace App\Test\BDD;

class ServiceObject {
    protected $data;
    protected $dockerHostIp;

    public function __construct($data, $dockerHostIp = null) {
        $this->data = $data;
        $this->dockerHostIp = $dockerHostIp;
    }

    public function __isset($name) {
        return in_array($name, ['host']) || preg_match('/^p(\d+)/', $name);
    }

    public function __get($name) {
        $value = null;
        if($name === 'host') {
            $value = $this->dockerHostIp? $this->dockerHostIp : $this->data['NetworkSettings']['IPAddress'];
        } elseif(preg_match('/^p(\d+)/', $name, $matches)) {
            $value = $this->getPort($matches[1]);
        }

        return $value;
    }

    protected function getPort($port) {
        if($this->dockerHostIp) {
            $ports = $this->data['NetworkSettings']['Ports'];
            if(isset($ports[$port . '/tcp'])) {
                $key = $port . '/tcp';
            } else if(isset($ports[$port . '/udp'])) {
                $key = $port . '/udp';
            }

            if(isset($key)) {
                $port = $ports[$key][0]['HostPort'];
            } else {
                $port = null;
            }
        }

        return $port;
    }
}
