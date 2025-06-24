/** Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved. */
package com.dell.isgedge.hzp.tests;

import com.dell.isgedge.qa.commons.exceptions.QAException;
import com.dell.isgedge.qa.commons.messaging.MessagingClient;
import com.dell.isgedge.qa.hzp.api.ApiBaseTest;
import org.assertj.core.api.Assertions;
import org.testng.annotations.Test;

public class NatsTests extends ApiBaseTest {
  @Test
  public void natsHealthCheck() {
    try {
      MessagingClient.getMessagingClient("jetstream");
    } catch (QAException e) {
      Assertions.fail(e.getMessage(), e);
    }
  }
}
