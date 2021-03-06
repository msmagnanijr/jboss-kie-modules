#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home

mkdir -p $JBOSS_HOME/bin/launch
sudo mkdir -p /var/run/secrets/kubernetes.io/serviceaccount/
sudo touch /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
sudo -E bash -c  'echo "testNamespace" > /var/run/secrets/kubernetes.io/serviceaccount/namespace'
sudo -E bash -c  'echo "custom-token" > /var/run/secrets/kubernetes.io/serviceaccount/token'

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-common/added/launch/jboss-kie-common.sh $JBOSS_HOME/bin/launch/jboss-kie-common.sh


source  $JBOSS_HOME/bin/launch/launch-common.sh

setup() {
    echo "Starting mock http server."
    python3 $BATS_TEST_DIRNAME/../../../tools/python-mock-server/python-mock-server.py &
    sleep 3
}

teardown() {
    rm -rf $JBOSS_HOME
    sudo rm -rf /var/run/secrets
    #close mock server
    curl -s http://localhost:8080/halt
}

# do not change the values here
export RHPAM_CENTRAL_CONSOLE_SERVICE_HOST="localhost"
export RHPAM_CENTRAL_CONSOLE_SERVICE_PORT_HTTP="8080"
export WORKBENCH_SERVICE_NAME="rhpam-central-console"
export KIE_SERVER_STARTUP_STRATEGY="OpenShiftStartupStrategy"

@test "test container lifecycle hook - scale up scenario" {
    export KIE_SERVER_ID="rhpam-kieserevr-scale-up"
    run bash $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-kieserver-hooks.sh
    [ "${lines[0]}" = "[INFO]KIE Server Replicas is 1, notifying Controller for KIE Server: [rhpam-kieserevr-scale-up]." ]
    [ "${lines[1]}" = "[INFO]Waiting for KIE Server: [rhpam-kieserevr-scale-up] to scale up for 45 seconds..." ]
    [ "${lines[2]}" = "[INFO]Controller successfully notified" ]
}

@test "test container lifecycle hook - scale down scenario" {
    export KIE_SERVER_ID="rhpam-kieserevr-scale-down"
    run bash $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-kieserver-hooks.sh
    [ "${lines[0]}" = "[INFO]Controller successfully notified" ]
}
