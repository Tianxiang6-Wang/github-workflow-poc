/** Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved. */
package com.dell.isgedge.hzp.performance;

import com.dell.isgedge.qa.commons.exceptions.QAException;
import com.dell.isgedge.qa.commons.messaging.MessagingClient;
import com.dell.isgedge.qa.commons.utils.DataGeneratorUtils;
import com.dell.isgedge.qa.hzp.events.EventsHelper;
import org.apache.jmeter.protocol.java.sampler.AbstractJavaSamplerClient;
import org.apache.jmeter.protocol.java.sampler.JavaSamplerContext;
import org.apache.jmeter.samplers.SampleResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NatsLoadTest extends AbstractJavaSamplerClient {
  private static final Logger LOG = LoggerFactory.getLogger(NatsLoadTest.class);
  private MessagingClient messagingClient;

  @Override
  public void setupTest(JavaSamplerContext context) {
    try {
      this.messagingClient = MessagingClient.getMessagingClient("jetstream");
    } catch (QAException e) {
      LOG.error("Error while getting message client", e);
    }
  }

  @Override
  public SampleResult runTest(JavaSamplerContext javaSamplerContext) {
    String messageID = DataGeneratorUtils.getUUID();
    String message = null;
    try {
      message = EventsHelper.getSampleEvent(messageID);
    } catch (QAException e) {
      throw new RuntimeException(e);
    }
    SampleResult results = new SampleResult();
    results.setSampleLabel("NATS load test");
    results.sampleStart();
    try {
      this.messagingClient.publish("K-ORDERS.test-broker-kne-trigger-hzp", message);
      results.setSuccessful(true);
    } catch (QAException e) {
      LOG.error("Error while publishing message", e);
      // Add the error message to report
      results.setResponseMessage(e.toString());
      results.setSuccessful(false);
    }
    results.sampleEnd();
    return results;
  }

  @Override
  public void teardownTest(JavaSamplerContext context) {
    try {
      this.messagingClient.closeConnection();
    } catch (QAException e) {
      LOG.error("Error while close connection", e);
    }
  }
}
