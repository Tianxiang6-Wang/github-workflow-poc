/*
 * Copyright © 2023 Dell Inc. or its subsidiaries. All Rights Reserved.
 */

package com.dell.isgedge.hzp.helper;

import static org.assertj.core.api.Assertions.assertThat;

import com.dell.isgedge.qa.commons.api.client.ApiException;
import com.dell.isgedge.qa.commons.api.client.ApiResponse;
import com.dell.isgedge.qa.commons.utils.ApiClientUtils;
import com.dell.isgedge.qa.hzp.api.frucru.model.FrucruConfigurations;
import com.dell.isgedge.qa.hzp.api.onboarding.api.OwnershipVoucherApi;
import com.dell.isgedge.qa.hzp.api.onboarding.model.ListVouchers;
import com.dell.isgedge.qa.hzp.api.onboarding.model.OwnershipVoucher;
import com.dell.isgedge.qa.hzp.api.onboarding.model.OwnershipVoucherResponse;
import java.net.HttpURLConnection;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class OnboardingHelper {
  ApiClientUtils apiClientUtils = new ApiClientUtils();
  FrucruConfigurations frucruConfigurations = FrucruConfigurations.builder().build();
  private static final Logger LOG = LoggerFactory.getLogger(OnboardingHelper.class);
  private int offset = 0;
  private int limit = 100;

  /**
   * Helper method to return active voucher for a service tag
   *
   * @param serviceTag serviceTag to return voucher
   * @throws ApiException if any error during API call
   * @return OwnershipVoucher object with response data
   */
  public OwnershipVoucher getOwnershipVoucherByServiceTag(String serviceTag) throws ApiException {
    OwnershipVoucherApi ownershipVoucherApi =
        new OwnershipVoucherApi(
            apiClientUtils.getAPIClient(frucruConfigurations.getOnboardingSvcBaseUrl()));
    OwnershipVoucher listOwnershipVouchers =
        OwnershipVoucher.builder()
            .offset(offset)
            .limit(limit)
            .orderBy(OwnershipVoucher.SortOrder.DESC)
            .build();
    ApiResponse<OwnershipVoucherResponse> listVouchersResponse =
        ownershipVoucherApi.listVoucherByPaginationCallWithHttpInfo(listOwnershipVouchers);
    assertThat(listVouchersResponse.getStatusCode()).isEqualTo(HttpURLConnection.HTTP_OK);
    ListVouchers listVouchersData =
        listVouchersResponse.getData().getOwnershipVoucherResponseData().getVouchersByPagination();
    assertThat(listVouchersData).isNotNull();
    List<OwnershipVoucher> listVouchersDataItems = listVouchersData.getItems();
    assertThat(listVouchersDataItems).isNotNull();
    OwnershipVoucher ov =
        listVouchersDataItems.stream()
            .filter(
                filterOwnershipVoucher -> filterOwnershipVoucher.getServiceTag().equals(serviceTag))
            .findFirst()
            .orElse(null);
    assertThat(ov).isNotNull();
    return ov;
  }
}
