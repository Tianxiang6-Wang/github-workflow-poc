/** Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved. */
package com.dell.isgedge.hzp.tests;

import static org.awaitility.Awaitility.await;

import com.dell.isgedge.hzp.performance.NatsLoadTest;
import com.dell.isgedge.qa.commons.exceptions.QAException;
import com.dell.isgedge.qa.commons.jmeter.JmeterRunner;
import com.dell.isgedge.qa.commons.jmeter.JmeterTestPlan;
import com.dell.isgedge.qa.hzp.events.Events;
import java.util.concurrent.TimeUnit;
import org.assertj.core.api.Assertions;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

public class NATSDispatcherLoadTest {

  @Test
  @Parameters({"loopCount", "numberOfThreads", "rampupTime"})
  public void runPerformanceTest(int loopCount, int numberOfThreads, int rampupTime)
      throws QAException {
    JmeterTestPlan jmeterTestPlan =
        JmeterTestPlan.builder()
            .name("NATS dispatcher load test")
            .loopCount(loopCount)
            .numberOfThreads(numberOfThreads)
            .rampupTime(rampupTime)
            .logFileName("nats_results.jtl")
            .testClassName(NatsLoadTest.class.getName())
            .build();
    JmeterRunner jmeterRunner = new JmeterRunner();
    jmeterRunner.run(jmeterTestPlan);
    Events events = new Events();

    // verify number of events are added to DB
    await()
        .atMost(1, TimeUnit.MINUTES)
        .untilAsserted(
            () ->
                Assertions.assertThat(events.getEventsCountFromDatabase())
                    .isEqualTo(loopCount * numberOfThreads));
  }
}
