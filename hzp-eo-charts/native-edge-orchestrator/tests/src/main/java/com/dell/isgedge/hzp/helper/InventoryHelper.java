/*
 * Copyright © 2023 Dell Inc. or its subsidiaries. All Rights Reserved.
 */

package com.dell.isgedge.hzp.helper;

import static org.assertj.core.api.Assertions.assertThat;

import com.dell.isgedge.qa.commons.api.client.ApiException;
import com.dell.isgedge.qa.commons.api.client.ApiResponse;
import com.dell.isgedge.qa.commons.utils.ApiClientUtils;
import com.dell.isgedge.qa.hzp.api.frucru.model.FrucruConfigurations;
import com.dell.isgedge.qa.hzp.api.inventory.api.EceInventoryApi;
import com.dell.isgedge.qa.hzp.api.inventory.model.EceInventory;
import com.dell.isgedge.qa.hzp.api.inventory.model.EceInventoryFilter;
import com.dell.isgedge.qa.hzp.api.inventory.model.EceInventoryResponse;
import java.net.HttpURLConnection;
import java.util.ArrayList;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class InventoryHelper {
  ApiClientUtils apiClientUtils = new ApiClientUtils();
  FrucruConfigurations frucruConfigurations = FrucruConfigurations.builder().build();
  private static final Logger LOG = LoggerFactory.getLogger(InventoryHelper.class);

  /**
   * Helper method to update inventory recovery status by service tag
   *
   * @param serviceTag serviceTag to update inventory record
   * @throws ApiException if any error during API call
   * @return EceInventory object with response data
   */
  public EceInventory updateInventoryRecoveryStatusByServiceTagHelper(
      String serviceTag, String desiredRecoveryStatus) throws ApiException {
    EceInventoryApi eceInventoryApi =
        new EceInventoryApi(
            apiClientUtils.getAPIClient(frucruConfigurations.getInventorySvcBaseUrl()));
    LOG.info(
        "frucruConfigurations.getInventorySvcBaseUrl()"
            + frucruConfigurations.getInventorySvcBaseUrl());
    // update ECEInventory Recovery Status
    EceInventory eceInventory =
        EceInventory.builder().serviceTag(serviceTag).recoveryStatus(desiredRecoveryStatus).build();
    LOG.info(
        "updateRecoveryStatusMutationQuery api request \n"
            + eceInventory.updateRecoveryStatusMutationQuery());
    ApiResponse<EceInventoryResponse> updateEceInventoryRecoveryStatusResponse =
        eceInventoryApi.updateEceInventoryRecoveryStatusWithHttpInfo(eceInventory);
    assertThat(updateEceInventoryRecoveryStatusResponse).isNotNull();
    assertThat(updateEceInventoryRecoveryStatusResponse.getStatusCode())
        .isEqualTo(HttpURLConnection.HTTP_OK);
    EceInventory eceInventoryRecoveryStatusResponseDetails =
        updateEceInventoryRecoveryStatusResponse
            .getData()
            .getEceInventoryResponseData()
            .getEceInventoryResponse();
    String strResponse =
        (eceInventoryRecoveryStatusResponseDetails.toString() == null
            ? "-"
            : eceInventoryRecoveryStatusResponseDetails.toString());
    assertThat(eceInventoryRecoveryStatusResponseDetails.getServiceTag().equals(serviceTag));
    assertThat(
        eceInventoryRecoveryStatusResponseDetails
            .getRecoveryStatus()
            .equals(desiredRecoveryStatus));
    LOG.info("Recovery Status updated to --> " + desiredRecoveryStatus);
    LOG.info("Response - update inventory recovery status by ServiceTag API " + strResponse);
    return eceInventoryRecoveryStatusResponseDetails;
  }
  /**
   * Helper method to query inventory by service tag
   *
   * @param serviceTag serviceTag to query inventory
   * @throws ApiException if any error during API call
   * @return EceInventory object with response data
   */
  public EceInventory getEceByServiceTagHelper(String serviceTag) throws ApiException {

    EceInventoryApi eceInventoryApi =
        new EceInventoryApi(
            apiClientUtils.getAPIClient(frucruConfigurations.getInventorySvcBaseUrl()));
    LOG.info(
        "frucruConfigurations.getInventorySvcBaseUrl()"
            + frucruConfigurations.getInventorySvcBaseUrl());
    // Get ECE details by Service Tag
    EceInventory eceInventory = EceInventory.builder().serviceTag(serviceTag).build();
    LOG.info("Get inventory by ServiceTag API " + eceInventory.getEceInventoryByServiceTagQuery());
    ApiResponse<EceInventoryResponse> getEceInventoryResponse =
        eceInventoryApi.getEceInventoryByServiceTagWithHttpInfo(eceInventory);
    assertThat(getEceInventoryResponse).isNotNull();
    assertThat(getEceInventoryResponse.getStatusCode()).isEqualTo(HttpURLConnection.HTTP_OK);
    EceInventory eceInventoryResponseDetails =
        getEceInventoryResponse.getData().getEceInventoryResponseData().getEceInventoryResponse();
    String strResponse =
        (eceInventoryResponseDetails.toString() == null
            ? "-"
            : eceInventoryResponseDetails.toString());
    assertThat(eceInventoryResponseDetails.getServiceTag().equals(serviceTag));
    LOG.info("Response - get inventory by ServiceTag API " + strResponse);
    return eceInventoryResponseDetails;
  }

  /**
   * Helper method to query and return online ECE
   *
   * @return EceInventory object with response data
   */
  public EceInventory getOnlineEceHelper() throws ApiException {
    EceInventoryApi eceInventoryApi =
        new EceInventoryApi(
            apiClientUtils.getAPIClient(frucruConfigurations.getInventorySvcBaseUrl()));
    List<EceInventoryFilter> filters = new ArrayList<>();
    filters.add(
        EceInventoryFilter.builder()
            .filterByField(EceInventory.EceInventoryField.STATUS)
            .filterOperator(EceInventory.EceInventoryFilterOperator.EQUALS)
            .filterByFieldValue(EceInventory.Status.PROVISIONED.toString())
            .build());
    EceInventory eceInventory =
        EceInventory.builder()
            .offset(0)
            .limit(-1)
            .orderByField(EceInventory.EceInventoryField.NAME)
            .orderByFieldValue(EceInventory.Sort.ASC)
            .filters(filters)
            .build();

    LOG.info("Query is " + eceInventory.inventoryListQuery());
    ApiResponse<EceInventoryResponse> getEceInventoryResponse =
        eceInventoryApi.getEceInventoryListWithHttpInfo(eceInventory);
    List<EceInventory> onlineEceInventoryResponseList =
        getEceInventoryResponse
            .getData()
            .getEceInventoryResponseData()
            .getEceInventoryResponseList();
    assertThat(onlineEceInventoryResponseList).isNotNull();
    assertThat(onlineEceInventoryResponseList.size()).isGreaterThanOrEqualTo(1);
    LOG.info("Filter by CONNECTION = Online and return ece inventory record");
    EceInventory onlineEceInventory =
        onlineEceInventoryResponseList.stream()
            .filter(onlineEce -> "Online".equals(onlineEce.getConnection()))
            .findAny()
            .orElse(null);
    assertThat(onlineEceInventory).isNotNull();
    LOG.info("Returning online ECE info \n" + onlineEceInventory.toString());
    return onlineEceInventory;
  }
}
