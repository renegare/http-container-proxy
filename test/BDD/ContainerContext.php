<?php

namespace App\Test\BDD;

use Behat\Behat\Context\Context;
use Behat\Behat\Context\SnippetAcceptingContext;
use Behat\Gherkin\Node\PyStringNode;
use Behat\Gherkin\Node\TableNode;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use App\EtcdClient;
use Symfony\Component\Process\ProcessBuilder;
use Symfony\Component\Process\Process;
use Will\Be\Thrown;
use PHPUnit_Framework_Assert as unit;

class ContainerContext implements Context, SnippetAcceptingContext
{
    const BOOT2DOCKER_HOST_ENV='DOCKER_HOST';

    /** @var boolean */
    protected static $boot2DockerIp = null;
    /** @var string[] */
    protected $availabelServices;
    /** @var EnvironmentContext */
    protected $environmentContext;
    /** @var string */
    protected $image;
    /** @var string */
    protected $lastOutput;

    /**
     * Initializes context.
     *
     * Every scenario gets its own context instance.
     * You can also pass arbitrary arguments to the
     * context constructor through behat.yml.
     */
    public function __construct($image, $availabelServices = [])
    {
        $this->image              = $image;
        $this->availabelServices    = $availabelServices;
    }

    protected static function isBoot2Docker() {
        if(self::$boot2DockerIp === null) {
            self::$boot2DockerIp = getenv(self::BOOT2DOCKER_HOST_ENV);
            if(self::$boot2DockerIp) {
                self::$boot2DockerIp = preg_replace('#^[^\d]+([\d+\.]+):.+#', '$1', self::$boot2DockerIp);
            }
        }
        return !!self::$boot2DockerIp;
    }

    public function inspectService($serviceName) {
        $builder = new ProcessBuilder(['docker', 'inspect', $serviceName]);
        $process = $builder->getProcess();
        $process->mustRun();
        $data = json_decode($process->getOutput(), true);

        Thrown::when(!is_array($data) || !count($data), new \RuntimeException('Expected contianer expection to return something useful!?'));

        $data = array_shift($data);
        return new ServiceObject($data, $this->isBoot2Docker()? self::$boot2DockerIp : null);
    }

    public function getService($name) {
        $serviceName = $this->getRealServiceName($name);
        return $this->inspectService($serviceName);
    }

    /**
     * @When I run the command:
     * @Given I run the following commands:
     * @Given no services is running:
     * @Given I start the application environment:
     * @Given I start the aplication:
     */
    public function iRunTheCommand(PyStringNode $command)
    {
        $command = $this->renderCommand($command->getRaw());
        echo $command . "\n\n";
        $process = new Process($command);
        $process->mustRun(function ($type, $buffer) {
            if (Process::ERR !== $type) {
                echo $buffer;
            }
        });
        $this->lastOutput = $process->getOutput();
    }

    /**
     * @Then I expect the output of the command to be:
     */
    public function iExpectTheOutputToBe(PyStringNode $output)
    {
        unit::assertEquals(trim($output->getRaw()), trim($this->lastOutput));
    }

    protected function getRealServiceName($name) {
        return $this->availabelServices[$name];
    }

    protected function renderCommand($command) {
        $mustache   = new \Mustache_Engine;
        $context    = [];
        foreach(array_keys($this->availabelServices) as $key) {
            $context[$key] = $this->getService($key);
        }

        $context['image'] = $this->image;
        return $mustache->render($command, $context);
    }
}
