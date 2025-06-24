/*
 * Copyright © 2023 Dell Inc. or its subsidiaries. All Rights Reserved.
 */

package com.dell.isgedge.hzp.helper;

import static org.assertj.core.api.Assertions.assertThat;

import com.dell.isgedge.qa.commons.api.client.ApiException;
import com.dell.isgedge.qa.commons.api.client.ApiResponse;
import com.dell.isgedge.qa.commons.exceptions.QAException;
import com.dell.isgedge.qa.commons.models.Configuration;
import com.dell.isgedge.qa.commons.ssh.SSHConnection;
import com.dell.isgedge.qa.commons.utils.DataGeneratorUtils;
import com.dell.isgedge.qa.commons.utils.SSHUtils;
import com.dell.isgedge.qa.hzp.api.frucru.api.FrucruApi;
import com.dell.isgedge.qa.hzp.api.frucru.model.DownloadFRUVouchers;
import com.dell.isgedge.qa.hzp.api.frucru.model.EscrowKey;
import com.dell.isgedge.qa.hzp.api.frucru.model.FrucruResponse;
import com.dell.isgedge.qa.hzp.api.frucru.model.StartRecovery;
import com.dell.isgedge.qa.hzp.api.inventory.model.EceInventory;
import java.net.HttpURLConnection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class FrucruHelper {
  private static final Logger LOG = LoggerFactory.getLogger(FrucruHelper.class);
  InventoryHelper inventoryHelper = new InventoryHelper();
  private final String passphraseValue = "T" + DataGeneratorUtils.getRandomString(12) + "5!!";
  protected static SSHConnection sshConnection;
  Configuration config = new Configuration();
  public final String cmdPrefix = String.format("echo '%s' | sudo -S ", config.getSSH_PASSWORD());

  public FrucruHelper() throws QAException {}

  /**
   * Init escrow key if it is not already initialized
   *
   * @param frucruApi FrucruApi object
   * @throws ApiException if any error during API call
   */
  public void initEscrowKeyHelper(FrucruApi frucruApi) throws ApiException {
    EscrowKey escrowKey;
    escrowKey = EscrowKey.builder().passphrase(passphraseValue).build();
    LOG.info(
        "Query - to know the escrow key init status \n" + escrowKey.isEscrowkeyInitializedQuery());
    ApiResponse<FrucruResponse> frucruApiResponse =
        frucruApi.isEscrowKeyInitializedWithHttpInfo(escrowKey);
    assertThat(frucruApiResponse).isNotNull();
    assertThat(frucruApiResponse.getStatusCode()).isEqualTo(HttpURLConnection.HTTP_OK);
    LOG.info(
        "Query response - escrow key init status \n"
            + frucruApiResponse.getData().getFrucruResponseData().toString());
    if (!frucruApiResponse
        .getData()
        .getFrucruResponseData()
        .getIsEscrowKeyInitialized()
        .isInitialized()) {
      LOG.info("Mutation - initEscrowKey \n" + escrowKey.initEscrowKeyMutationQuery());
      ApiResponse<FrucruResponse> frucruInitApiResponse =
          frucruApi.initEscrowKeyWithHttpInfo(escrowKey);
      assertThat(frucruInitApiResponse).isNotNull();
      assertThat(frucruInitApiResponse.getStatusCode()).isEqualTo(HttpURLConnection.HTTP_OK);
      assertThat(
              frucruInitApiResponse
                  .getData()
                  .getFrucruResponseData()
                  .getInitEscrowKey()
                  .isInitialized())
          .isTrue();
      LOG.info(
          "Mutation response - initEscrowKey \n"
              + frucruInitApiResponse.getData().getFrucruResponseData().toString());
    } else {
      LOG.info("initEscrowKeyHelper: Escrow key is already initialized \n");
    }
  }

  /**
   * This method will run a command on ECE
   *
   * @param command command to be run on ECE
   * @throws QAException if any error when running command
   */
  public void runCommandOnECE(String command) throws QAException {
    SSHUtils.runCommandOnECE(sshConnection, command);
  }

  /**
   * This function will setup SSH connection to ECE
   *
   * @param config config containing parameters to connect to ECE
   */
  public void setupECESSHConnection(Configuration config) throws QAException {
    String sshUser = config.getSSH_USER_NAME();
    String pwd = config.getSSH_PASSWORD();
    String remoteHost = config.getSSH_REMOTE_HOST();
    LOG.info("SSH_USER_NAME -> " + sshUser + " and SSH_PASSWORD  -> " + pwd);
    LOG.info("Set up SSH connection for ip address -> " + remoteHost);
    sshConnection = new SSHConnection(config);
    LOG.info("Adding ECE ip to known hosts");
    SSHUtils.addIPToKnownHosts(remoteHost);
  }

  /** This function will disconnect SSH connection from ECE */
  public void disconnectSSHConnection() {
    LOG.info("Disconnecting ssh connection.");
    sshConnection.disconnect();
  }

  /**
   * Helper method to make call to Start recovery api
   *
   * @param frucruApi FrucruApi object
   * @param serviceTag serviceTag for start recovery
   * @return currentRecoveryStatus after approving MTLS restore
   * @throws ApiException if any error during API call
   */
  public String startRecoveryHelper(FrucruApi frucruApi, String serviceTag) throws ApiException {
    String currentRecoveryStatus;
    StartRecovery startRecovery =
        StartRecovery.builder().serviceTag(serviceTag).passphrase(passphraseValue).build();
    LOG.info("Mutation query --> \n" + startRecovery.startRecoveryMutationQuery());
    ApiResponse<FrucruResponse> frucruApiResponseStartRecovery =
        frucruApi.startRecoveryWithHttpInfo(startRecovery);
    currentRecoveryStatus =
        frucruApiResponseStartRecovery
            .getData()
            .getFrucruResponseData()
            .getStartRecovery()
            .getRecoveryStatus();
    assertThat(currentRecoveryStatus).isEqualTo("MTLS_APPROVED");
    return currentRecoveryStatus;
  }

  /**
   * Helper method to perform DI recovery steps with the serviceTag of online ECE
   *
   * @param frucruApi FrucruApi object
   * @param serviceTag serviceTag
   * @param ip IP of ECE
   * @throws ApiException if any error during API call
   * @throws QAException if any error for SSH command
   */
  public void performDiRecovery(FrucruApi frucruApi, String serviceTag, String ip)
      throws ApiException, QAException {
    EceInventory onlineEceInventory;
    String currentRecoveryStatus;
    assertThat(ip).isNotBlank().isNotEqualTo("0.0.0.0");
    config.setSSH_REMOTE_HOST(ip);
    String commandBoardSerialRecord =
        cmdPrefix + " bash -c 'cat /sys/class/dmi/id/board_serial > /hzp/fru/board_serial_record'";
    String commandRestorePendingMarker =
        cmdPrefix + " bash -c 'echo -n DiRecovery > /hzp/fru/restore_pending_marker'";
    String commandRestartECEAgent = cmdPrefix + " bash -c 'systemctl restart ece-agent.service'";
    LOG.info("Start DI recovery on EO for serviceTag --> " + serviceTag + "\n");
    LOG.info("InitEscrowKey, if not initialized\n");
    initEscrowKeyHelper(frucruApi);
    LOG.info("Update recovery status to READY_FOR_MTLS_RESTORE\n");
    onlineEceInventory =
        inventoryHelper.updateInventoryRecoveryStatusByServiceTagHelper(
            serviceTag, "READY_FOR_MTLS_RESTORE");
    LOG.info("Call startRecovery api to set recovery status to MTLS_APPROVED\n");
    currentRecoveryStatus = startRecoveryHelper(frucruApi, serviceTag);
    LOG.info("Recovery Status updated to --> " + currentRecoveryStatus);
    LOG.info("Update recovery status to DI_RECOVERY_PENDING\n");
    onlineEceInventory =
        inventoryHelper.updateInventoryRecoveryStatusByServiceTagHelper(
            serviceTag, "DI_RECOVERY_PENDING");
    // ECE side commands
    LOG.info("Start DI recovery on ECE for serviceTag --> " + serviceTag + "\n");
    setupECESSHConnection(config);
    LOG.info("Executing command" + commandBoardSerialRecord + "\n");
    runCommandOnECE(commandBoardSerialRecord);
    LOG.info("Executing command" + commandRestorePendingMarker + "\n");
    runCommandOnECE(commandRestorePendingMarker);
    LOG.info("Restarting ECE Agent\n");
    runCommandOnECE(commandRestartECEAgent);
    LOG.info("ECE Agent restarted..\n");
    disconnectSSHConnection();
  }

  /**
   * Helper method to make call to downloadFruVoucher
   *
   * @param frucruApi FrucruApi object
   * @return DownloadFRUVouchers object
   * @throws ApiException if any error during API call
   */
  public DownloadFRUVouchers downloadFRUVouchersHelper(FrucruApi frucruApi) throws ApiException {
    DownloadFRUVouchers downloadFRUVouchers;
    boolean success = false;
    downloadFRUVouchers = DownloadFRUVouchers.builder().build();
    ApiResponse<FrucruResponse> frucruApiResponse = null;
    LOG.info(
        "Mutation query - download FRU Vouchers\n"
            + downloadFRUVouchers.downloadFruVoucherMutationQuery());
    int retryCount = 0;
    // retry has been added here for java.net.SocketTimeoutException: timeout
    while (retryCount < 5) {
      try {
        frucruApiResponse = frucruApi.downloadFRUVouchersWithHttpInfo(downloadFRUVouchers);
        success = true;
        break; // Successful response received, exit the retry loop
      } catch (Exception e) {
        System.out.println(
            "downloadFRUVouchersHelper attempt "
                + retryCount
                + ": Request failed with message "
                + e.getMessage());
        retryCount++;
      }
    }
    if (!success) {
      throw new ApiException(
          "ApiException - Unable to download fru voucher, max retries reached..");
    }
    assertThat(frucruApiResponse).isNotNull();
    assertThat(frucruApiResponse.getStatusCode()).isEqualTo(HttpURLConnection.HTTP_OK);
    LOG.info(
        "Response - download FRU Vouchers\n" + frucruApiResponse.getData().getFrucruResponseData());
    return frucruApiResponse.getData().getFrucruResponseData().getDownloadFRUVouchers();
  }
}
