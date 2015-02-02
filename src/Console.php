<?php

namespace App;

use Symfony\Component\Console\Application;
use App\Command\GenerateProxyCommand;

class Console extends Application {
    /** @var Pimple */
    protected $container;

    /**
     * {@inheritdoc}
     */
    public function __construct($name = 'HCP', $version = 'UNKNOWN') {
        parent::__construct($name, $version);
        $this->loadCommands();
    }

    protected function loadCommands() {
        // $this->addContainerAwareCommand(new PushCommand);
        $this->add(new GenerateProxyCommand);
    }
}
