<?php

namespace App\Test\BDD;

use Behat\Behat\Context\Context;
use Behat\Behat\Context\SnippetAcceptingContext;
use Behat\Gherkin\Node\PyStringNode;
use Behat\Gherkin\Node\TableNode;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use App\EtcdClient;

class EtcdServiceContext implements Context, SnippetAcceptingContext
{
    /** @var EtcdClient */
    protected $client;
    /** @var ContainerContext */
    protected $containerContext;

    /**
     * @Given the etcd namespace :namespace does not exist
     */
    public function iTheEtcdNamespaceDoesNotExist($namespace)
    {
        $client = $this->getClient();
        if($client->exists($namespace)) {
            $client->remove($namespace);
        }
    }

    /**
     * @Given I set the following etcd data:
     */
    public function iHaveTheFollowingEtcdData(TableNode $data)
    {
        $client = $this->getClient();
        foreach($data->getHash() as $row) {
            $client->set($row['key'], $row['value']);
        }
    }

    protected function getClient() {
        if(!$this->client) {
            $service = $this->containerContext->getService('etcd');
            $host = sprintf('http://%s:%s', $service->host, $service->p4001);
            $this->client = new EtcdClient($host);
        }
        return $this->client;
    }

    /** @BeforeScenario */
    public function gatherContexts(BeforeScenarioScope $scope)
    {
        $environment = $scope->getEnvironment();

        $this->containerContext = $environment->getContext('App\Test\BDD\ContainerContext');
    }
}
