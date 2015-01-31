<?php

namespace App\Test\BDD;

use Behat\Behat\Context\Context;
use Behat\Behat\Context\SnippetAcceptingContext;
use Behat\Gherkin\Node\PyStringNode;
use Behat\Gherkin\Node\TableNode;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;

/**
 * Defines application features from the specific context.
 */
class WebPageContext implements Context, SnippetAcceptingContext
{
    /** @BeforeScenario */
    public function gatherContexts(BeforeScenarioScope $scope)
    {
        $environment = $scope->getEnvironment();

        $this->minkContext = $environment->getContext('Behat\MinkExtension\Context\MinkContext');
    }

    /**
     * @Given I am on the :name page
     */
    public function iAmOnThePage($page)
    {
        $page = $this->getPage($page);
        $this->minkContext->visit($page->getPath());
    }

    protected function getPage($type) {
        $type = explode(' ', $type);
        $type = array_map(function($part) {
            return ucfirst(strtolower($part));
        }, $type);
        $class = sprintf(__NAMESPACE__ . '\Page\%sPage', implode('', $type));
        return new $class;
    }
}
