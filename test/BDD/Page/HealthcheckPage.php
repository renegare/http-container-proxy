<?php

namespace App\Test\BDD\Page;

use Behat\MinkExtension\Context\RawMinkContext;

class HealthcheckPage {
    protected $path = '/healthcheck/';

    public function getPath() {
        return $this->path;
    }
}
