/*
 * Copyright © 2023 Dell Inc. or its subsidiaries. All Rights Reserved.
 */

package com.dell.isgedge.hzp.tests;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

import com.dell.isgedge.hzp.helper.FrucruHelper;
import com.dell.isgedge.hzp.helper.InventoryHelper;
import com.dell.isgedge.hzp.helper.OnboardingHelper;
import com.dell.isgedge.qa.commons.api.client.ApiException;
import com.dell.isgedge.qa.commons.exceptions.QAException;
import com.dell.isgedge.qa.commons.utils.ApiClientUtils;
import com.dell.isgedge.qa.hzp.api.ApiBaseTest;
import com.dell.isgedge.qa.hzp.api.frucru.api.FrucruApi;
import com.dell.isgedge.qa.hzp.api.frucru.model.DownloadFRUVouchers;
import com.dell.isgedge.qa.hzp.api.inventory.model.EceInventory;
import com.dell.isgedge.qa.hzp.api.onboarding.model.OwnershipVoucher;
import java.util.concurrent.TimeUnit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class FrucruDIRecoveryTest extends ApiBaseTest {
  ApiClientUtils apiClientUtils = new ApiClientUtils();
  private static final int TIMEOUT = 240;
  private static final int POLL_INTERVAL = 10;
  private static final Logger LOG = LoggerFactory.getLogger(FrucruDIRecoveryTest.class);
  InventoryHelper inventoryHelper = new InventoryHelper();
  OnboardingHelper onboardingHelper = new OnboardingHelper();
  private final String fruCruSvcBaseUrl = System.getenv("FRU_CRU_SVC_BASE_URL");

  /**
   * Verify DI Recovery process <a href=
   * "https://qtest.gtie.dell.com/p/181/portal/project#tab=testdesign&object=1&id=4302492">TC-8229</a>
   *
   * @throws ApiException if error occurs during API call
   * @throws QAException if error occurs during SSH commands
   */
  // TODO test will be enabled once hardware ECE is setup for regression run
  // @Test
  public void performDiRecoveryAndCheckFruVoucherIsAvailable() throws ApiException, QAException {
    FrucruHelper frucruHelper = new FrucruHelper();
    LOG.info("fruCruSvcBaseUrl is -> " + fruCruSvcBaseUrl + "\n");
    FrucruApi frucruApi = new FrucruApi(apiClientUtils.getAPIClient(fruCruSvcBaseUrl));
    EceInventory onlineEceInventory = inventoryHelper.getOnlineEceHelper();
    String serviceTag = onlineEceInventory.getServiceTag();
    String ipAddress = onlineEceInventory.getIp();
    frucruHelper.performDiRecovery(frucruApi, serviceTag, ipAddress);

    await()
        .atMost(TIMEOUT, TimeUnit.SECONDS)
        .pollInterval(POLL_INTERVAL, TimeUnit.SECONDS)
        .untilAsserted(
            () -> {
              OwnershipVoucher ov = onboardingHelper.getOwnershipVoucherByServiceTag(serviceTag);
              assertThat(ov).isNotNull();
              assertThat(ov.getServiceTag()).isEqualTo(serviceTag);
              assertThat(ov.getStatus()).isEqualTo("TO0 Completed");
              LOG.info("OwnershipVoucher is -> \n" + ov + "\n");
            });
    LOG.info("\n Ownership voucher assertion success: TO0 Completed\n");
    await()
        .atMost(TIMEOUT, TimeUnit.SECONDS)
        .pollInterval(POLL_INTERVAL, TimeUnit.SECONDS)
        .untilAsserted(
            () -> {
              EceInventory eceInventoryResponse =
                  inventoryHelper.getEceByServiceTagHelper(serviceTag);
              assertThat(eceInventoryResponse).isNotNull();
              String recoStatus = eceInventoryResponse.getRecoveryStatus();
              String eceOnlineOfflineStatus = eceInventoryResponse.getConnection();
              assertThat(recoStatus).isEqualTo("FACTORY_RESET_NEEDED");
              assertThat(eceOnlineOfflineStatus).isEqualTo("Online");
              LOG.info("ECE Inventory Response -> \n" + eceInventoryResponse + "\n");
            });
    LOG.info("\n Inventory recovery status assertion success: FACTORY_RESET_NEEDED\n");
    await()
        .atMost(TIMEOUT, TimeUnit.SECONDS)
        .pollInterval(POLL_INTERVAL, TimeUnit.SECONDS)
        .untilAsserted(
            () -> {
              DownloadFRUVouchers downloadFRUVouchers =
                  frucruHelper.downloadFRUVouchersHelper(frucruApi);
              assertThat(downloadFRUVouchers).isNotNull();
              String encodedVoucherString = downloadFRUVouchers.getBase64voucherdata();
              assertThat(encodedVoucherString).isNotBlank();
              assertThat(downloadFRUVouchers.getFileName()).isEqualTo("fru-vouchers.zip");
              assertThat(downloadFRUVouchers.getContentType()).isEqualTo("application/zip");
              assertThat(downloadFRUVouchers.getContentLength()).isGreaterThanOrEqualTo(1000);
              LOG.info("\nBase64 encoded file -> \n" + encodedVoucherString + "\n");
            });
    LOG.info("\n Fru voucher downloadFRUVouchers assertion success\n");
  }
}
