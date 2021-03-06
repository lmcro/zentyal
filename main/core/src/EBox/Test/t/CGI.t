use strict;
use warnings;

use Test::Tester ;
use Test::More tests => 38;
use Test::Exception;

use lib '../../..';

use EBox::Global::TestStub;

EBox::Global::TestStub::fake();

use_ok ('EBox::Test::CGI', qw(:all));
use EBox::CGI::Base;

*EBox::CGI::Base::_validateReferer = sub { return 1; };

runCgiTest();
cgiErrorAssertionsTest();
muteHtmlOutputTest();

sub runCgiTest
{
    my @cases = (
		 { cgiParams => [] },
		 { cgiParams => [primate => 'bonobo', otherParameter => 'macaco'] },
		 { cgiParams => [forceError => 0, otherParameter => 'macaco'] },
		 { cgiParams => [forceError => 1, otherParameter => 'macaco'], awaitedError => 1 },
    );

    foreach my $case_r (@cases) {
        my $cgi = new EBox::CGI::DumbCGI;
        if ($cgi->hasRun()) {
            die 'cgi reported as runned before it is really runned';
        }

        my @cgiParams    = @{ $case_r->{cgiParams}  };
        my $awaitedError = $case_r->{awaitedError};

        lives_ok { runCgi($cgi, @cgiParams) } "runCgi() call with cgi's parameters: @cgiParams";
        ok $cgi->hasRun(), "Checking if cgi has run"  ;

        my $error =  $cgi->{error};
        my $hasError =  defined $error;
        ok $hasError, 'Checking for error status in CGI'      if $awaitedError;
        ok !$hasError, 'Checking if CGI has not any error'    if !$awaitedError;
    }
}

sub cgiErrorAssertionsTest
{
    my $testName;
    my $errorFreeCgi = new EBox::CGI::DumbCGI;
    my $errorRiddenCgi = new EBox::CGI::DumbCGI;
    $errorRiddenCgi->{error} = 'a error';

    # cgiErrorNotOk..

    $testName = 'Checking positive assertion for cgiErrorNotOk';

    check_test(
            sub { cgiErrorNotOk($errorFreeCgi, $testName); },
            { ok => 1, name =>  $testName, }
    );


    $testName = 'Checking negative assertion for cgiErrorNotOk';
    check_test(
            sub { cgiErrorNotOk($errorRiddenCgi, $testName); },
            { ok => 0, name =>  $testName },
    );

    # cgiErrorOk..
    $testName = 'Checking positive assertion for cgiErrorOk';
    check_test(
            sub { cgiErrorOk($errorRiddenCgi, $testName) },
            { ok => 1, name =>  $testName },
    );


    $testName  = 'Checking negative assertion for cgiErrorOk';
    check_test(
            sub { cgiErrorOk($errorFreeCgi, $testName); },
            { ok => 0, name =>  $testName },
    );
}

sub muteHtmlOutputTest
{
    muteHtmlOutput('EBox::CGI::NoiseCGI');
    my $cgi = new EBox::CGI::NoiseCGI;
    runCgi($cgi);

    my $noise = $cgi->noise();
    is $noise, 0, 'Checking that after muteHtmlOutput the cgi has used the overriden =print sub';
}

package EBox::CGI::DumbCGI;
use base 'EBox::CGI::Base';

use Plack::Request;

sub new
{
    my ($class, %params) = @_;
    unless (defined $params{request}) {
        $params{request} = new Plack::Request({});
    }
    my $self = $class->SUPER::new(%params);
    $self->{hasRun} = 0;

    bless $self, $class;
    return $self;
}

sub  _process
{
    my ($self) = @_;
    $self->{hasRun} = 1;

    my $errorParam = $self->param('forceError');

    if ($errorParam) {
	    $self->{error} = 'Error forced by parameter';
    }
}

sub hasRun
{
    my ($self ) = @_;
    return $self->{hasRun};
}

# to eliminate html output while running cgi:
sub _print
{
}

package EBox::CGI::NoiseCGI;
use base 'EBox::CGI::DumbCGI';

my $noise = 0;

sub new
{
    my ($class) = shift @_;
    $noise = 0;
    return $class->SUPER::new(@_);
}

sub _print
{
    $noise = 1;
}

sub noise
{
    return $noise;
}

1;
